//
//  InMemoryRideRepository.swift
//  bicitaxi-conductor
//
//  In-memory implementation of RideRepository for demo/testing
//

import Foundation

/// In-memory implementation of RideRepository
/// TODO: Swap for Firestore/REST implementation when backend is added.
final class InMemoryRideRepository: RideRepository, @unchecked Sendable {
    
    private var rides: [String: Ride] = [:]
    private let queue = DispatchQueue(label: "InMemoryRideRepository", attributes: .concurrent)
    
    init() {}
    
    // MARK: - Private Helpers
    
    private func generateId() -> String {
        UUID().uuidString
    }
    
    // MARK: - RideRepository
    
    func create(_ ride: Ride) async throws -> Ride {
        var newRide = ride
        
        // Generate ID if not set
        if newRide.id.isEmpty {
            newRide.id = generateId()
        }
        
        // Ensure timestamps are set
        let now = Date()
        if newRide.createdAt > now {
            newRide.createdAt = now
        }
        newRide.updatedAt = now
        
        // Store
        queue.async(flags: .barrier) {
            self.rides[newRide.id] = newRide
        }
        
        return newRide
    }
    
    func update(_ ride: Ride) async throws {
        var updatedRide = ride
        updatedRide.updatedAt = Date()
        
        queue.async(flags: .barrier) {
            self.rides[ride.id] = updatedRide
        }
    }
    
    func historyForClient(id: String) async throws -> [Ride] {
        return queue.sync {
            rides.values
                .filter { $0.clientId == id }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    func historyForDriver(id: String) async throws -> [Ride] {
        return queue.sync {
            rides.values
                .filter { $0.driverId == id }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    func pendingRides() async throws -> [Ride] {
        return queue.sync {
            rides.values
                .filter { $0.status == .searchingDriver && $0.driverId == nil }
                .sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    func getRide(id: String) async throws -> Ride? {
        return queue.sync {
            rides[id]
        }
    }
    
    // MARK: - Demo Data Generation
    
    /// Generate dummy pending rides near a location with addresses and names
    func generateDummyRides(around center: RideLocationPoint) async {
        // Sample data: (clientId, latOffset, lonOffset, pickupAddr, dropoffAddr, clientName)
        let dummyRides: [(String, Double, Double, String, String, String)] = [
            ("client-001", 0.003, 0.002, "Calle 85 #15-25, Bogotá", "Centro Comercial Andino", "Carlos García"),
            ("client-002", -0.002, 0.004, "Carrera 7 #72-41, Bogotá", "Parque de la 93", "María López"),
            ("client-003", 0.004, -0.003, "Av. El Dorado #68-51, Bogotá", "Terminal de Transporte", "Juan Martínez"),
            ("client-004", -0.001, -0.002, "Calle 26 #13-51, Bogotá", "Centro Internacional", "Ana Rodríguez"),
        ]
        
        for (clientId, latOffset, lonOffset, pickupAddr, dropoffAddr, _) in dummyRides {
            let pickup = RideLocationPoint(
                latitude: center.latitude + latOffset,
                longitude: center.longitude + lonOffset,
                address: pickupAddr
            )
            let dropoff = RideLocationPoint(
                latitude: center.latitude + latOffset + 0.005,
                longitude: center.longitude + lonOffset + 0.005,
                address: dropoffAddr
            )
            
            let ride = Ride.demoPending(
                clientId: clientId,
                pickup: pickup,
                dropoff: dropoff
            )
            
            _ = try? await create(ride)
        }
    }
}
