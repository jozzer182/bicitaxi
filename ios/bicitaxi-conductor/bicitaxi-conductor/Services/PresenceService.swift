//
//  PresenceService.swift
//  bicitaxi-conductor
//
//  Service for managing driver presence in geographic cells.
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
    let id: String
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
        let cutoff = Date().addingTimeInterval(-600)
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
        self.role = PresenceRole(rawValue: data["role"] as? String ?? "driver") ?? .driver
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

/// Service for managing driver presence in geographic cells.
@MainActor
class PresenceService: ObservableObject {
    
    @Published var isOnline: Bool = false
    @Published var currentCellCanonical: String = ""
    
    private let db = Firestore.firestore()
    private let appName: String
    private let role: PresenceRole
    
    private var heartbeatTimer: Timer?
    private var currentCellId: String?
    private var listeners: [ListenerRegistration] = []
    
    static let heartbeatInterval: TimeInterval = 180
    static let presenceTtl: TimeInterval = 86400
    static let staleThreshold: TimeInterval = 600
    
    init(appName: String = "bicitaxi_conductor", role: PresenceRole = .driver) {
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
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func presenceRef(cellId: String, uid: String) -> DocumentReference {
        db.collection("cells").document(cellId)
            .collection("presence").document(uid)
    }
    
    func updatePresence(lat: Double, lng: Double, activeRideId: String? = nil) async {
        guard let uid = currentUserId else {
            print("⚠️ PresenceService: No authenticated user")
            return
        }
        
        let cellId = GeoCellService.computeCellIdFromCoords(lat: lat, lng: lng)
        let canonical = GeoCellService.computeCanonical(lat: lat, lng: lng)
        
        print("📍 Driver updating presence: cellId=\(cellId), canonical=\(canonical)")
        
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
            currentCellCanonical = canonical
            isOnline = true
            print("✅ Driver presence updated in cell: \(cellId)")
        } catch {
            print("❌ Failed to update driver presence: \(error)")
        }
    }
    
    private func deletePresence(cellId: String, uid: String) async {
        do {
            try await presenceRef(cellId: cellId, uid: uid).delete()
            print("🗑️ Deleted old presence from cell: \(cellId)")
        } catch {
            print("⚠️ Failed to delete old presence: \(error)")
        }
    }
    
    func startHeartbeat(
        getLatitude: @escaping () -> Double,
        getLongitude: @escaping () -> Double,
        getActiveRideId: (() -> String?)? = nil
    ) {
        stopHeartbeat()
        
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
        
        print("💓 Driver heartbeat started (interval: \(Int(Self.heartbeatInterval / 60))m)")
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        print("💔 Driver heartbeat stopped")
    }
    
    func goOffline() async {
        stopHeartbeat()
        
        if let uid = currentUserId, let cellId = currentCellId {
            await deletePresence(cellId: cellId, uid: uid)
            currentCellId = nil
        }
        
        isOnline = false
        currentCellCanonical = ""
        print("📴 Driver went offline")
    }
    
    func removeAllListeners() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
}
