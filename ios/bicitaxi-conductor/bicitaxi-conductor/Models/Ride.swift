//
//  Ride.swift
//  bicitaxi-conductor
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

// MARK: - Demo Data

extension Ride {
    /// Create a demo pending ride for testing
    static func demoPending(
        clientId: String,
        pickup: RideLocationPoint,
        dropoff: RideLocationPoint? = nil
    ) -> Ride {
        Ride(
            id: UUID().uuidString,
            clientId: clientId,
            pickup: pickup,
            dropoff: dropoff,
            status: .searchingDriver
        )
    }
}
