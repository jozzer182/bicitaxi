//
//  Ride.swift
//  bicitaxi
//
//  Main ride model
//

import Foundation

/// Represents a bike taxi ride
struct Ride: Identifiable, Codable, Equatable {
    var id: String
    var clientId: String
    var driverId: String?
    var pickup: RideLocationPoint
    var dropoff: RideLocationPoint?
    var status: RideStatus
    var createdAt: Date
    var updatedAt: Date
    
    /// Create a new ride with the given parameters
    init(
        id: String = "",
        clientId: String,
        driverId: String? = nil,
        pickup: RideLocationPoint,
        dropoff: RideLocationPoint? = nil,
        status: RideStatus = .requested,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.driverId = driverId
        self.pickup = pickup
        self.dropoff = dropoff
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Returns a new ride with updated status
    func withStatus(_ newStatus: RideStatus) -> Ride {
        var updated = self
        updated.status = newStatus
        updated.updatedAt = Date()
        return updated
    }
    
    /// Returns a new ride with assigned driver
    func withDriver(_ driverId: String) -> Ride {
        var updated = self
        updated.driverId = driverId
        updated.updatedAt = Date()
        return updated
    }
    
    // MARK: - Serialization Helpers
    // Uses canonical field names matching Flutter app for Firebase compatibility.
    
    /// Convert to dictionary for Firestore/network requests.
    /// Uses canonical field names (lat, lng) matching Flutter app.
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "clientId": clientId,
            "pickup": pickup.toDictionary(),
            "status": status.rawValue,
            "createdAt": Int(createdAt.timeIntervalSince1970 * 1000),
            "updatedAt": Int(updatedAt.timeIntervalSince1970 * 1000)
        ]
        
        if let driverId = driverId {
            dict["driverId"] = driverId
        }
        
        if let dropoff = dropoff {
            dict["dropoff"] = dropoff.toDictionary()
        }
        
        return dict
    }
    
    /// Alias for toDictionary() - use this explicitly for Firebase operations.
    func toFirestore() -> [String: Any] {
        return toDictionary()
    }
    
    /// Create from Firestore document data.
    /// TODO: Update to handle Firestore Timestamp types when Firebase is added.
    static func fromFirestore(_ dict: [String: Any], id documentId: String? = nil) -> Ride? {
        guard let clientId = dict["clientId"] as? String,
              let pickupDict = dict["pickup"] as? [String: Any],
              let pickup = RideLocationPoint.fromDictionary(pickupDict),
              let statusString = dict["status"] as? String,
              let status = RideStatus(rawValue: statusString) else {
            return nil
        }
        
        let rideId = documentId ?? (dict["id"] as? String) ?? ""
        let driverId = dict["driverId"] as? String
        
        var dropoff: RideLocationPoint? = nil
        if let dropoffDict = dict["dropoff"] as? [String: Any] {
            dropoff = RideLocationPoint.fromDictionary(dropoffDict)
        }
        
        let createdAtMs = dict["createdAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
        let updatedAtMs = dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
        
        return Ride(
            id: rideId,
            clientId: clientId,
            driverId: driverId,
            pickup: pickup,
            dropoff: dropoff,
            status: status,
            createdAt: Date(timeIntervalSince1970: createdAtMs / 1000),
            updatedAt: Date(timeIntervalSince1970: updatedAtMs / 1000)
        )
    }
    
    /// Estimated fare in Colombian Pesos (demo calculation)
    /// No cents used in Colombia, values typically range from $5,000 to $50,000 COP
    var estimatedFare: Int {
        guard let dropoff = dropoff else { return 5000 }
        
        // Simple distance-based calculation (demo)
        let latDiff = abs(dropoff.latitude - pickup.latitude)
        let lonDiff = abs(dropoff.longitude - pickup.longitude)
        let distance = sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111 // ~km
        
        return max(5000, Int(distance * 4000)) // $5,000 minimum, ~$4,000/km
    }
}

// MARK: - Firebase Constants

extension Ride {
    /// Firebase collection name for rides.
    static let collectionName = "rides"
}

// MARK: - Demo Data

extension Ride {
    /// Create a demo ride for testing
    static func demo(
        clientId: String = "client-demo",
        pickup: RideLocationPoint = RideLocationPoint(latitude: 19.4326, longitude: -99.1332),
        dropoff: RideLocationPoint? = RideLocationPoint(latitude: 19.4400, longitude: -99.1400)
    ) -> Ride {
        Ride(
            id: UUID().uuidString,
            clientId: clientId,
            pickup: pickup,
            dropoff: dropoff,
            status: .requested
        )
    }
}
