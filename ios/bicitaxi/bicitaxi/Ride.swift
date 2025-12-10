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
    // TODO: Map to Firestore/REST payload when backend is added.
    
    /// Convert to dictionary for network requests
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "clientId": clientId,
            "pickup": [
                "latitude": pickup.latitude,
                "longitude": pickup.longitude,
                "address": pickup.address as Any
            ],
            "status": status.rawValue,
            "createdAt": createdAt.timeIntervalSince1970 * 1000,
            "updatedAt": updatedAt.timeIntervalSince1970 * 1000
        ]
        
        if let driverId = driverId {
            dict["driverId"] = driverId
        }
        
        if let dropoff = dropoff {
            dict["dropoff"] = [
                "latitude": dropoff.latitude,
                "longitude": dropoff.longitude,
                "address": dropoff.address as Any
            ]
        }
        
        return dict
    }
    
    /// Estimated fare (demo calculation)
    var estimatedFare: Double {
        guard let dropoff = dropoff else { return 5.0 }
        
        // Simple distance-based calculation (demo)
        let latDiff = abs(dropoff.latitude - pickup.latitude)
        let lonDiff = abs(dropoff.longitude - pickup.longitude)
        let distance = sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111 // ~km
        
        return max(5.0, distance * 10.0) // $5 minimum, $10/km
    }
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
