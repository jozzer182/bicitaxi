//
//  RequestService.swift
//  bicitaxi
//
//  Service for managing ride requests.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Status of a ride request.
enum RequestStatus: String {
    case open = "open"
    case assigned = "assigned"
    case cancelled = "cancelled"
    case completed = "completed"
}

/// Location data for pickup/dropoff.
struct LocationPoint {
    let lat: Double
    let lng: Double
    let address: String? // Geocoded address name
    
    init(lat: Double, lng: Double, address: String? = nil) {
        self.lat = lat
        self.lng = lng
        self.address = address
    }
    
    init?(map: [String: Any]) {
        guard let lat = map["lat"] as? Double,
              let lng = map["lng"] as? Double else { return nil }
        self.lat = lat
        self.lng = lng
        self.address = map["address"] as? String
    }
    
    func toMap() -> [String: Any] {
        var result: [String: Any] = ["lat": lat, "lng": lng]
        if let address = address {
            result["address"] = address
        }
        return result
    }
}

/// Ride request data model.
struct RideRequest: Identifiable {
    let id: String // requestId
    let requestId: String
    let createdByUid: String
    let pickup: LocationPoint
    let dropoff: LocationPoint?
    let status: RequestStatus
    let assignedDriverUid: String?
    let createdAt: Date
    let updatedAt: Date
    let cellId: String
    let expiresAt: Date
    
    // Driver real-time location (updated during "assigned" status)
    let driverLat: Double?
    let driverLng: Double?
    let driverLocationUpdatedAt: Date?
    
    // Client heartbeat - updated every 30s while client is actively waiting
    let lastHeartbeat: Date?
    
    // Display names for UI
    let clientName: String?
    let driverName: String?
    static let staleThreshold: TimeInterval = 180 // 3 minutes
    
    /// Returns true if the request is fresh (heartbeat within stale threshold)
    var isFresh: Bool {
        if status != .open { return true } // Assigned/completed are always valid
        let heartbeat = lastHeartbeat ?? createdAt
        return Date().timeIntervalSince(heartbeat) < RideRequest.staleThreshold
    }
    
    /// Duration since creation.
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
    
    /// Human-readable age string.
    var ageString: String {
        let mins = Int(age / 60)
        if mins < 1 { return "Ahora" }
        if mins < 60 { return "Hace \(mins) min" }
        let hours = Int(age / 3600)
        if hours < 24 { return "Hace \(hours) h" }
        let days = Int(age / 86400)
        return "Hace \(days) días"
    }
    
    init(
        requestId: String,
        createdByUid: String,
        pickup: LocationPoint,
        dropoff: LocationPoint? = nil,
        status: RequestStatus,
        assignedDriverUid: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        cellId: String,
        expiresAt: Date,
        driverLat: Double? = nil,
        driverLng: Double? = nil,
        driverLocationUpdatedAt: Date? = nil,
        lastHeartbeat: Date? = nil,
        clientName: String? = nil,
        driverName: String? = nil
    ) {
        self.id = requestId
        self.requestId = requestId
        self.createdByUid = createdByUid
        self.pickup = pickup
        self.dropoff = dropoff
        self.status = status
        self.assignedDriverUid = assignedDriverUid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cellId = cellId
        self.expiresAt = expiresAt
        self.driverLat = driverLat
        self.driverLng = driverLng
        self.driverLocationUpdatedAt = driverLocationUpdatedAt
        self.lastHeartbeat = lastHeartbeat
        self.clientName = clientName
        self.driverName = driverName
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let pickupMap = data["pickup"] as? [String: Any],
              let pickup = LocationPoint(map: pickupMap) else { return nil }
        
        self.id = document.documentID
        self.requestId = data["requestId"] as? String ?? document.documentID
        self.createdByUid = data["createdByUid"] as? String ?? ""
        self.pickup = pickup
        
        if let dropoffMap = data["dropoff"] as? [String: Any] {
            self.dropoff = LocationPoint(map: dropoffMap)
        } else {
            self.dropoff = nil
        }
        
        self.status = RequestStatus(rawValue: data["status"] as? String ?? "open") ?? .open
        self.assignedDriverUid = data["assignedDriverUid"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.cellId = data["cellId"] as? String ?? ""
        self.expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date()
        
        // Driver location fields
        self.driverLat = data["driverLat"] as? Double
        self.driverLng = data["driverLng"] as? Double
        self.driverLocationUpdatedAt = (data["driverLocationUpdatedAt"] as? Timestamp)?.dateValue()
        
        // Heartbeat field
        self.lastHeartbeat = (data["lastHeartbeat"] as? Timestamp)?.dateValue()
        
        // Display names
        self.clientName = data["clientName"] as? String
        self.driverName = data["driverName"] as? String
    }
    
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "requestId": requestId,
            "createdByUid": createdByUid,
            "pickup": pickup.toMap(),
            "status": status.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "cellId": cellId,
            "expiresAt": Timestamp(date: expiresAt),
            "lastHeartbeat": FieldValue.serverTimestamp() // Initial heartbeat
        ]
        if let dropoff = dropoff {
            dict["dropoff"] = dropoff.toMap()
        }
        if let assignedDriverUid = assignedDriverUid {
            dict["assignedDriverUid"] = assignedDriverUid
        }
        if let clientName = clientName {
            dict["clientName"] = clientName
        }
        if let driverName = driverName {
            dict["driverName"] = driverName
        }
        return dict
    }
}

/// Service for managing ride requests.
@MainActor
class RequestService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var openRequests: [RideRequest] = []
    @Published var myRequests: [RideRequest] = []
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var expansionTimer: Timer?
    private var isExpanded: Bool = false
    
    /// Request TTL (24 hours)
    static let requestTtl: TimeInterval = 86400
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        // Cancel timer and listeners synchronously
        expansionTimer?.invalidate()
        for listener in listeners {
            listener.remove()
        }
    }
    
    // MARK: - Current User
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Request Reference
    
    private func requestRef(cellId: String, requestId: String) -> DocumentReference {
        db.collection("cells").document(cellId)
            .collection("requests").document(requestId)
    }
    
    // MARK: - Create Request
    
    func createRequest(
        pickupLat: Double,
        pickupLng: Double,
        dropoffLat: Double? = nil,
        dropoffLng: Double? = nil,
        pickupAddress: String? = nil,
        dropoffAddress: String? = nil
    ) async -> RideRequest? {
        guard let uid = currentUserId else {
            print("⚠️ RequestService: No authenticated user")
            return nil
        }
        
        let cellId = GeoCellService.computeCellIdFromCoords(lat: pickupLat, lng: pickupLng)
        let requestId = db.collection("cells").document().documentID
        
        // Fetch current user's name from Firestore users collection
        var clientName = "Pasajero"
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            if let data = userDoc.data(), let name = data["name"] as? String, !name.isEmpty {
                clientName = name
            }
        } catch {
            print("⚠️ Could not fetch user name: \(error)")
        }
        
        print("📝 Creating request in cell: \(cellId) by \(clientName)")
        
        var dropoff: LocationPoint?
        if let dropoffLat = dropoffLat, let dropoffLng = dropoffLng {
            dropoff = LocationPoint(lat: dropoffLat, lng: dropoffLng, address: dropoffAddress)
        }
        
        let request = RideRequest(
            requestId: requestId,
            createdByUid: uid,
            pickup: LocationPoint(lat: pickupLat, lng: pickupLng, address: pickupAddress),
            dropoff: dropoff,
            status: .open,
            assignedDriverUid: nil,
            createdAt: Date(),
            updatedAt: Date(),
            cellId: cellId,
            expiresAt: Date().addingTimeInterval(Self.requestTtl),
            clientName: clientName
        )
        
        do {
            try await requestRef(cellId: cellId, requestId: requestId).setData(request.toFirestore())
            
            // Save to client's history
            await HistoryService.createClientHistory(
                rideId: requestId,
                clientUid: uid,
                clientName: clientName,
                pickupLat: pickupLat,
                pickupLng: pickupLng,
                pickupAddress: pickupAddress,
                dropoffLat: dropoffLat,
                dropoffLng: dropoffLng,
                dropoffAddress: dropoffAddress
            )
            
            print("✅ Request created: \(requestId)")
            return request
        } catch {
            print("❌ Failed to create request: \(error)")
            return nil
        }
    }
    
    // MARK: - Cancel Request
    
    func cancelRequest(cellId: String, requestId: String) async {
        guard let uid = currentUserId else { return }
        
        // Get driver uid if assigned
        var driverUid: String?
        do {
            let requestDoc = try await requestRef(cellId: cellId, requestId: requestId).getDocument()
            if let data = requestDoc.data() {
                driverUid = data["assignedDriverUid"] as? String
            }
        } catch {
            print("⚠️ Could not fetch request data: \(error)")
        }
        
        do {
            try await requestRef(cellId: cellId, requestId: requestId).updateData([
                "status": "cancelled",
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            // Update history for both parties
            await HistoryService.markRideCancelled(rideId: requestId, clientUid: uid, driverUid: driverUid)
            
            print("❌ Request cancelled: \(requestId)")
        } catch {
            print("❌ Failed to cancel request: \(error)")
        }
    }
    
    // MARK: - Assign Driver
    
    func assignDriver(cellId: String, requestId: String, driverUid: String) async {
        do {
            try await requestRef(cellId: cellId, requestId: requestId).updateData([
                "status": "assigned",
                "assignedDriverUid": driverUid,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("🚴 Driver assigned to request: \(requestId)")
        } catch {
            print("❌ Failed to assign driver: \(error)")
        }
    }
    
    // MARK: - Complete Request
    
    func completeRequest(cellId: String, requestId: String) async {
        do {
            try await requestRef(cellId: cellId, requestId: requestId).updateData([
                "status": "completed",
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("✅ Request completed: \(requestId)")
        } catch {
            print("❌ Failed to complete request: \(error)")
        }
    }
    
    // MARK: - Update Heartbeat
    
    /// Updates the heartbeat timestamp for a request.
    /// Called periodically by client to indicate they are still waiting.
    func updateHeartbeat(cellId: String, requestId: String) async {
        do {
            try await requestRef(cellId: cellId, requestId: requestId).updateData([
                "lastHeartbeat": FieldValue.serverTimestamp()
            ])
            print("💓 Request heartbeat: \(requestId)")
        } catch {
            print("⚠️ Failed to update heartbeat: \(error)")
        }
    }
    
    // MARK: - Update Driver Location
    
    /// Updates driver's real-time location for a request.
    /// Called by conductor app during assigned/arriving status.
    func updateDriverLocation(cellId: String, requestId: String, lat: Double, lng: Double) async {
        do {
            try await requestRef(cellId: cellId, requestId: requestId).updateData([
                "driverLat": lat,
                "driverLng": lng,
                "driverLocationUpdatedAt": FieldValue.serverTimestamp()
            ])
            print("📍 Driver location updated for request: \(requestId)")
        } catch {
            print("❌ Failed to update driver location: \(error)")
        }
    }
    
    // MARK: - Watch Single Request
    
    /// Watches a single request document for real-time updates.
    /// Used by client app to track driver location and status changes.
    @Published var activeRequest: RideRequest?
    private var requestListener: ListenerRegistration?
    
    func watchRequest(cellId: String, requestId: String) {
        requestListener?.remove()
        requestListener = requestRef(cellId: cellId, requestId: requestId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error watching request: \(error)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    Task { @MainActor in
                        self.activeRequest = nil
                    }
                    return
                }
                
                let request = RideRequest(document: snapshot)
                Task { @MainActor in
                    self.activeRequest = request
                }
            }
    }
    
    func stopWatchingRequest() {
        requestListener?.remove()
        requestListener = nil
        activeRequest = nil
    }

    
    // MARK: - Watch Open Requests
    
    func watchOpenRequests(lat: Double, lng: Double, includeNeighbors: Bool = false) {
        removeAllListeners()
        
        let cellIds: [String]
        if includeNeighbors {
            cellIds = GeoCellService.computeAllCellIds(lat: lat, lng: lng)
        } else {
            cellIds = [GeoCellService.computeCellIdFromCoords(lat: lat, lng: lng)]
        }
        
        print("👀 Watching requests in \(cellIds.count) cells")
        
        var requestsByCellId = [String: [RideRequest]]()
        
        for cellId in cellIds {
            let listener = db.collection("cells").document(cellId)
                .collection("requests")
                .whereField("status", isEqualTo: "open")
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error watching requests: \(error)")
                        return
                    }
                    
                    let requests = snapshot?.documents.compactMap { RideRequest(document: $0) } ?? []
                    requestsByCellId[cellId] = requests
                    
                    // Flatten and deduplicate by requestId
                    var combined = [String: RideRequest]()
                    for reqs in requestsByCellId.values {
                        for req in reqs {
                            combined[req.requestId] = req
                        }
                    }
                    
                    // Sort by createdAt descending
                    let sorted = combined.values.sorted { $0.createdAt > $1.createdAt }
                    
                    Task { @MainActor in
                        self.openRequests = sorted
                    }
                }
            
            listeners.append(listener)
        }
    }
    
    // MARK: - Watch Open Requests with Expansion
    
    func watchOpenRequestsWithExpansion(
        lat: Double,
        lng: Double,
        expandDelay: TimeInterval = 20
    ) {
        removeAllListeners()
        isExpanded = false
        
        // Start with current cell only
        watchOpenRequests(lat: lat, lng: lng, includeNeighbors: false)
        
        // Set timer to expand
        expansionTimer?.invalidate()
        expansionTimer = Timer.scheduledTimer(withTimeInterval: expandDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if !self.isExpanded {
                    self.watchOpenRequests(lat: lat, lng: lng, includeNeighbors: true)
                    self.isExpanded = true
                    print("🔄 Expanded to watch 9 cells")
                }
            }
        }
    }
    
    // MARK: - Watch My Requests
    
    func watchMyRequests() {
        guard let uid = currentUserId else { return }
        
        // Using collectionGroup query
        let listener = db.collectionGroup("requests")
            .whereField("createdByUid", isEqualTo: uid)
            .whereField("status", in: ["open", "assigned"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error watching my requests: \(error)")
                    return
                }
                
                let requests = snapshot?.documents.compactMap { RideRequest(document: $0) } ?? []
                
                Task { @MainActor in
                    self.myRequests = requests
                }
            }
        
        listeners.append(listener)
    }
    
    // MARK: - Cleanup
    
    func removeAllListeners() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        expansionTimer?.invalidate()
        expansionTimer = nil
    }
}
