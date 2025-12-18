//
//  HistoryService.swift
//  bicitaxi
//
//  Service to manage ride history in Firestore
//  Each user has their own history collection at /users/{uid}/history/
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Model for a ride history entry
struct RideHistoryEntry: Identifiable, Codable {
    let id: String  // Same as rideId
    let role: String  // "client" or "driver"
    
    // Locations
    let pickupLat: Double
    let pickupLng: Double
    let pickupAddress: String?
    let dropoffLat: Double?
    let dropoffLng: Double?
    let dropoffAddress: String?
    
    // Parties
    let clientUid: String
    let clientName: String
    let driverUid: String?
    let driverName: String?
    
    // Timeline
    let createdAt: Date
    let assignedAt: Date?
    let completedAt: Date?
    let cancelledAt: Date?
    
    // Status
    let status: String  // "pending", "assigned", "completed", "cancelled"
    
    /// Display string for the ride date
    var dateString: String {
        let now = Date()
        let diff = Calendar.current.dateComponents([.day], from: createdAt, to: now)
        
        if diff.day == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Hoy \(formatter.string(from: createdAt))"
        } else if diff.day == 1 {
            return "Ayer"
        } else if let days = diff.day, days < 7 {
            return "Hace \(days) días"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: createdAt)
        }
    }
    
    /// Status display text
    var statusText: String {
        switch status {
        case "completed": return "Completado"
        case "cancelled": return "Cancelado"
        case "assigned": return "En curso"
        default: return "Pendiente"
        }
    }
    
    /// Time display string
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
}

/// Service to manage ride history in Firestore
class HistoryService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var history: [RideHistoryEntry] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Get reference to user's history collection
    private func historyRef(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("history")
    }
    
    /// Fetch user's ride history
    func fetchHistory() async {
        guard let uid = currentUserId else {
            await MainActor.run { history = [] }
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let snapshot = try await historyRef(uid)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            let entries = snapshot.documents.compactMap { doc -> RideHistoryEntry? in
                let data = doc.data()
                return RideHistoryEntry(
                    id: doc.documentID,
                    role: data["role"] as? String ?? "client",
                    pickupLat: data["pickupLat"] as? Double ?? 0,
                    pickupLng: data["pickupLng"] as? Double ?? 0,
                    pickupAddress: data["pickupAddress"] as? String,
                    dropoffLat: data["dropoffLat"] as? Double,
                    dropoffLng: data["dropoffLng"] as? Double,
                    dropoffAddress: data["dropoffAddress"] as? String,
                    clientUid: data["clientUid"] as? String ?? "",
                    clientName: data["clientName"] as? String ?? "Cliente",
                    driverUid: data["driverUid"] as? String,
                    driverName: data["driverName"] as? String,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    assignedAt: (data["assignedAt"] as? Timestamp)?.dateValue(),
                    completedAt: (data["completedAt"] as? Timestamp)?.dateValue(),
                    cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                    status: data["status"] as? String ?? "pending"
                )
            }
            
            await MainActor.run {
                self.history = entries
                self.isLoading = false
            }
        } catch {
            print("⚠️ Error fetching history: \(error)")
            await MainActor.run {
                self.history = []
                self.isLoading = false
            }
        }
    }
    
    /// Watch user's history with real-time updates
    func watchHistory() {
        guard let uid = currentUserId else { return }
        
        listener?.remove()
        isLoading = true
        
        listener = historyRef(uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ History listener error: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.history = []
                    self.isLoading = false
                    return
                }
                
                self.history = documents.compactMap { doc -> RideHistoryEntry? in
                    let data = doc.data()
                    return RideHistoryEntry(
                        id: doc.documentID,
                        role: data["role"] as? String ?? "client",
                        pickupLat: data["pickupLat"] as? Double ?? 0,
                        pickupLng: data["pickupLng"] as? Double ?? 0,
                        pickupAddress: data["pickupAddress"] as? String,
                        dropoffLat: data["dropoffLat"] as? Double,
                        dropoffLng: data["dropoffLng"] as? Double,
                        dropoffAddress: data["dropoffAddress"] as? String,
                        clientUid: data["clientUid"] as? String ?? "",
                        clientName: data["clientName"] as? String ?? "Cliente",
                        driverUid: data["driverUid"] as? String,
                        driverName: data["driverName"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        assignedAt: (data["assignedAt"] as? Timestamp)?.dateValue(),
                        completedAt: (data["completedAt"] as? Timestamp)?.dateValue(),
                        cancelledAt: (data["cancelledAt"] as? Timestamp)?.dateValue(),
                        status: data["status"] as? String ?? "pending"
                    )
                }
                self.isLoading = false
            }
    }
    
    func stopWatching() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Static write methods (used by RequestService)
    
    /// Save history entry for a user
    static func saveHistoryEntry(uid: String, rideId: String, data: [String: Any]) async {
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("history")
                .document(rideId)
                .setData(data, merge: true)
            print("📜 Saved history for user \(uid), ride \(rideId)")
        } catch {
            print("⚠️ Failed to save history: \(error)")
        }
    }
    
    /// Create client history entry when request is created
    static func createClientHistory(
        rideId: String,
        clientUid: String,
        clientName: String,
        pickupLat: Double,
        pickupLng: Double,
        pickupAddress: String?,
        dropoffLat: Double?,
        dropoffLng: Double?,
        dropoffAddress: String?
    ) async {
        let data: [String: Any] = [
            "role": "client",
            "pickupLat": pickupLat,
            "pickupLng": pickupLng,
            "pickupAddress": pickupAddress as Any,
            "dropoffLat": dropoffLat as Any,
            "dropoffLng": dropoffLng as Any,
            "dropoffAddress": dropoffAddress as Any,
            "clientUid": clientUid,
            "clientName": clientName,
            "createdAt": Timestamp(date: Date()),
            "status": "pending"
        ]
        await saveHistoryEntry(uid: clientUid, rideId: rideId, data: data)
    }
    
    /// Create driver history entry when ride is accepted
    static func createDriverHistory(
        rideId: String,
        clientUid: String,
        clientName: String,
        driverUid: String,
        driverName: String,
        pickupLat: Double,
        pickupLng: Double,
        pickupAddress: String?,
        dropoffLat: Double?,
        dropoffLng: Double?,
        dropoffAddress: String?
    ) async {
        let data: [String: Any] = [
            "role": "driver",
            "pickupLat": pickupLat,
            "pickupLng": pickupLng,
            "pickupAddress": pickupAddress as Any,
            "dropoffLat": dropoffLat as Any,
            "dropoffLng": dropoffLng as Any,
            "dropoffAddress": dropoffAddress as Any,
            "clientUid": clientUid,
            "clientName": clientName,
            "driverUid": driverUid,
            "driverName": driverName,
            "createdAt": Timestamp(date: Date()),
            "assignedAt": Timestamp(date: Date()),
            "status": "assigned"
        ]
        await saveHistoryEntry(uid: driverUid, rideId: rideId, data: data)
        
        // Also update client's history with driver info
        let clientUpdate: [String: Any] = [
            "driverUid": driverUid,
            "driverName": driverName,
            "assignedAt": Timestamp(date: Date()),
            "status": "assigned"
        ]
        await saveHistoryEntry(uid: clientUid, rideId: rideId, data: clientUpdate)
    }
    
    /// Mark ride completed for both parties
    static func markRideCompleted(rideId: String, clientUid: String, driverUid: String?) async {
        print("🔍 markRideCompleted called: rideId=\(rideId), clientUid=\(clientUid), driverUid=\(driverUid ?? "nil")")
        
        let update: [String: Any] = [
            "completedAt": Timestamp(date: Date()),
            "status": "completed"
        ]
        
        // Only update client history if we have a valid uid
        if !clientUid.isEmpty {
            await saveHistoryEntry(uid: clientUid, rideId: rideId, data: update)
        } else {
            print("⚠️ Cannot update client history: clientUid is empty")
        }
        
        if let driverUid = driverUid, !driverUid.isEmpty {
            await saveHistoryEntry(uid: driverUid, rideId: rideId, data: update)
        }
    }
    
    /// Mark ride cancelled
    static func markRideCancelled(rideId: String, clientUid: String, driverUid: String?) async {
        let update: [String: Any] = [
            "cancelledAt": Timestamp(date: Date()),
            "status": "cancelled"
        ]
        await saveHistoryEntry(uid: clientUid, rideId: rideId, data: update)
        if let driverUid = driverUid {
            await saveHistoryEntry(uid: driverUid, rideId: rideId, data: update)
        }
    }
    
    deinit {
        listener?.remove()
    }
}
