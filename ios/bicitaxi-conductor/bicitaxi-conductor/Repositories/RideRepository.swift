//
//  RideRepository.swift
//  bicitaxi-conductor
//
//  Repository protocol for ride data operations
//

import Foundation

/// Protocol for ride data operations
/// TODO: Replace with a real backend implementation (e.g. Firebase, REST API).
protocol RideRepository: Sendable {
    /// Create a new ride
    func create(_ ride: Ride) async throws -> Ride
    
    /// Update an existing ride
    func update(_ ride: Ride) async throws
    
    /// Get ride history for a client
    func historyForClient(id: String) async throws -> [Ride]
    
    /// Get ride history for a driver
    func historyForDriver(id: String) async throws -> [Ride]
    
    /// Get all pending rides (for drivers)
    func pendingRides() async throws -> [Ride]
    
    /// Get a ride by ID
    func getRide(id: String) async throws -> Ride?
}
