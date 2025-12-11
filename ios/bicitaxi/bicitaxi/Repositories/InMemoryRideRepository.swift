//
//  InMemoryRideRepository.swift
//  bicitaxi
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
}
