//
//  PresenceService.swift
//  bicitaxi
//
//  Service for managing user presence in geographic cells.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// User role for presence tracking.
enum PresenceRole: String {
    case driver = "driver"
    case client = "client"
}

/// Presence data model.
struct PresenceData: Identifiable {
    let id: String // uid
    let uid: String
    let role: PresenceRole
    let lastSeen: Date
    let expiresAt: Date
    let lat: Double
    let lng: Double
    let cellId: String
    let activeRideId: String?
    let platform: String
    let app: String
    let updatedAt: Date
    
    var isStale: Bool {
        let cutoff = Date().addingTimeInterval(-600) // 10 minutes
        return lastSeen < cutoff
    }
    
    init(
        uid: String,
        role: PresenceRole,
        lastSeen: Date,
        expiresAt: Date,
        lat: Double,
        lng: Double,
        cellId: String,
        activeRideId: String? = nil,
        platform: String,
        app: String,
        updatedAt: Date
    ) {
        self.id = uid
        self.uid = uid
        self.role = role
        self.lastSeen = lastSeen
        self.expiresAt = expiresAt
        self.lat = lat
        self.lng = lng
        self.cellId = cellId
        self.activeRideId = activeRideId
        self.platform = platform
        self.app = app
        self.updatedAt = updatedAt
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.uid = data["uid"] as? String ?? document.documentID
        self.role = PresenceRole(rawValue: data["role"] as? String ?? "client") ?? .client
        self.lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date()
        self.expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lat = data["lat"] as? Double ?? 0.0
        self.lng = data["lng"] as? Double ?? 0.0
        self.cellId = data["cellId"] as? String ?? ""
        self.activeRideId = data["activeRideId"] as? String
        self.platform = data["platform"] as? String ?? "unknown"
        self.app = data["app"] as? String ?? "unknown"
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "role": role.rawValue,
            "lastSeen": FieldValue.serverTimestamp(),
            "expiresAt": Timestamp(date: expiresAt),
            "lat": lat,
            "lng": lng,
            "cellId": cellId,
            "platform": platform,
            "app": app,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let activeRideId = activeRideId {
            dict["activeRideId"] = activeRideId
        }
        return dict
    }
}

/// Service for managing user presence in geographic cells.
@MainActor
class PresenceService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var driverCount: Int = 0
    @Published var nearbyDrivers: [PresenceData] = []
    @Published var isOnline: Bool = false
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let appName: String
    private let role: PresenceRole
    
    private var heartbeatTimer: Timer?
    private var currentCellId: String?
    private var listeners: [ListenerRegistration] = []
    
    /// Track currently watched cells to avoid re-creating listeners unnecessarily
    private var currentWatchedCellIds: Set<String> = []
    
    /// Heartbeat interval (3 minutes)
    static let heartbeatInterval: TimeInterval = 180
    
    /// Presence TTL (24 hours)
    static let presenceTtl: TimeInterval = 86400
    
    /// Stale threshold (4 minutes) - drivers not seen in this time are considered offline
    static let staleThreshold: TimeInterval = 240
    
    // MARK: - Initialization
    
    init(appName: String, role: PresenceRole) {
        self.appName = appName
        self.role = role
    }
    
    deinit {
        // Cancel timer and listeners synchronously using stored references
        heartbeatTimer?.invalidate()
        for listener in listeners {
            listener.remove()
        }
    }
    
    // MARK: - Current User
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Presence Reference
    
    private func presenceRef(cellId: String, uid: String) -> DocumentReference {
        db.collection("cells").document(cellId)
            .collection("presence").document(uid)
    }
    
    // MARK: - Update Presence
    
    func updatePresence(lat: Double, lng: Double, activeRideId: String? = nil) async {
        guard let uid = currentUserId else {
            print("⚠️ PresenceService: No authenticated user")
            return
        }
        
        let cellId = GeoCellService.computeCellIdFromCoords(lat: lat, lng: lng)
        let canonical = GeoCellService.computeCanonical(lat: lat, lng: lng)
        
        print("📍 Updating presence: cellId=\(cellId), canonical=\(canonical)")
        
        // If cell changed, delete old presence
        if let oldCellId = currentCellId, oldCellId != cellId {
            await deletePresence(cellId: oldCellId, uid: uid)
        }
        
        let presence = PresenceData(
            uid: uid,
            role: role,
            lastSeen: Date(),
            expiresAt: Date().addingTimeInterval(Self.presenceTtl),
            lat: lat,
            lng: lng,
            cellId: cellId,
            activeRideId: activeRideId,
            platform: "ios_native",
            app: appName,
            updatedAt: Date()
        )
        
        do {
            try await presenceRef(cellId: cellId, uid: uid).setData(presence.toFirestore())
            currentCellId = cellId
            isOnline = true
            print("✅ Presence updated in cell: \(cellId)")
        } catch {
            print("❌ Failed to update presence: \(error)")
        }
    }
    
    // MARK: - Delete Presence
    
    private func deletePresence(cellId: String, uid: String) async {
        do {
            try await presenceRef(cellId: cellId, uid: uid).delete()
            print("🗑️ Deleted old presence from cell: \(cellId)")
        } catch {
            print("⚠️ Failed to delete old presence: \(error)")
        }
    }
    
    // MARK: - Heartbeat
    
    func startHeartbeat(
        getLatitude: @escaping () -> Double,
        getLongitude: @escaping () -> Double,
        getActiveRideId: (() -> String?)? = nil
    ) {
        stopHeartbeat()
        
        // Immediate first update
        Task {
            await updatePresence(
                lat: getLatitude(),
                lng: getLongitude(),
                activeRideId: getActiveRideId?()
            )
        }
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: Self.heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePresence(
                    lat: getLatitude(),
                    lng: getLongitude(),
                    activeRideId: getActiveRideId?()
                )
            }
        }
        
        print("💓 Heartbeat started (interval: \(Int(Self.heartbeatInterval / 60))m)")
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        print("💔 Heartbeat stopped")
    }
    
    // MARK: - Go Offline
    
    func goOffline() async {
        stopHeartbeat()
        
        if let uid = currentUserId, let cellId = currentCellId {
            await deletePresence(cellId: cellId, uid: uid)
            currentCellId = nil
        }
        
        isOnline = false
        print("📴 User went offline")
    }
    
    // MARK: - Watch Driver Count
    
    /// Watch driver count with cell-based optimization.
    /// Only recreates listeners if the geocell actually changes.
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lng: Longitude
    ///   - forceRefresh: If true, forces re-evaluation of stale drivers without recreating listeners
    func watchDriverCount(lat: Double, lng: Double, forceRefresh: Bool = false) {
        let cellIds = Set(GeoCellService.computeAllCellIds(lat: lat, lng: lng))
        
        // If cells haven't changed and not forcing refresh, skip recreation
        if cellIds == currentWatchedCellIds && !forceRefresh {
            // Cells unchanged - listeners are already active
            // Just log occasionally for debugging (not every call)
            return
        }
        
        // Cells changed - log and recreate listeners
        print("🔄 [PresenceService] Cell change detected, recreating listeners")
        print("👀 Watching driver count at lat=\(lat), lng=\(lng)")
        let canonicals = GeoCellService.computeAllCanonicals(lat: lat, lng: lng)
        print("👀 Primary cell: \(canonicals[0]) -> \(Array(cellIds)[0])")
        print("👀 Stale threshold: \(Self.staleThreshold / 60) minutes")
        print("👀 Watching \(cellIds.count) cells total")
        
        removeAllListeners()
        currentWatchedCellIds = cellIds
        
        var counts = [String: Int]()
        
        for cellId in cellIds {
            // Query ALL drivers, then filter client-side with fresh cutoff
            // This ensures stale check is always current, not a static timestamp
            let listener = db.collection("cells").document(cellId)
                .collection("presence")
                .whereField("role", isEqualTo: "driver")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error watching presence in \(cellId): \(error)")
                        return
                    }
                    
                    // Filter with FRESH cutoff on each snapshot update
                    let now = Date()
                    let cutoff = now.addingTimeInterval(-Self.staleThreshold)
                    
                    let freshDrivers = (snapshot?.documents ?? []).filter { doc in
                        let data = doc.data()
                        guard let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                            return false
                        }
                        return lastSeenTimestamp.dateValue() > cutoff
                    }
                    
                    if freshDrivers.count > 0 {
                        print("✅ Found \(freshDrivers.count) fresh driver(s) in cell: \(cellId)")
                        for doc in freshDrivers {
                            let data = doc.data()
                            print("   └─ Driver uid=\(doc.documentID), lastSeen=\(data["lastSeen"] ?? "nil")")
                        }
                    }
                    
                    counts[cellId] = freshDrivers.count
                    let total = counts.values.reduce(0, +)
                    
                    Task { @MainActor in
                        self.driverCount = total
                    }
                }
            
            listeners.append(listener)
        }
    }
    
    // MARK: - Watch Nearby Drivers
    
    func watchNearbyDrivers(lat: Double, lng: Double) {
        removeAllListeners()
        
        let cellIds = GeoCellService.computeAllCellIds(lat: lat, lng: lng)
        
        print("👀 Watching nearby drivers in \(cellIds.count) cells")
        
        var driversByCellId = [String: [PresenceData]]()
        
        for cellId in cellIds {
            // Query ALL drivers, then filter client-side with fresh cutoff
            let listener = db.collection("cells").document(cellId)
                .collection("presence")
                .whereField("role", isEqualTo: "driver")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error watching nearby drivers: \(error)")
                        return
                    }
                    
                    // Filter with FRESH cutoff on each snapshot update
                    let now = Date()
                    let cutoff = now.addingTimeInterval(-Self.staleThreshold)
                    
                    let freshDocs = (snapshot?.documents ?? []).filter { doc in
                        let data = doc.data()
                        guard let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                            return false
                        }
                        return lastSeenTimestamp.dateValue() > cutoff
                    }
                    
                    let drivers = freshDocs.compactMap { PresenceData(document: $0) }
                    driversByCellId[cellId] = drivers
                    
                    // Flatten all drivers
                    let allDrivers = driversByCellId.values.flatMap { $0 }
                    
                    Task { @MainActor in
                        self.nearbyDrivers = Array(allDrivers)
                        self.driverCount = allDrivers.count
                    }
                }
            
            listeners.append(listener)
        }
    }
    
    // MARK: - Cleanup
    
    func removeAllListeners() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        currentWatchedCellIds.removeAll()
    }
    
    /// Force refresh stale evaluation without recreating listeners
    func refreshStaleEvaluation(lat: Double, lng: Double) {
        // This will just re-check the current cached data
        // The snapshot listeners will re-evaluate freshness on their next callback
        watchDriverCount(lat: lat, lng: lng, forceRefresh: false)
    }
}
