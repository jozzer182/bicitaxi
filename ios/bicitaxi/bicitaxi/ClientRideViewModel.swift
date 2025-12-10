//
//  ClientRideViewModel.swift
//  bicitaxi
//
//  View model for client ride operations
//

import Foundation
import SwiftUI
import Combine

/// View model for client ride flow
@MainActor
class ClientRideViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current active ride (if any)
    @Published var activeRide: Ride?
    
    /// Ride history
    @Published var history: [Ride] = []
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let repo: any RideRepository
    private let currentUserId = "client-demo"
    
    // MARK: - Initialization
    
    init(repo: any RideRepository) {
        self.repo = repo
    }
    
    // MARK: - Public Methods
    
    /// Request a new ride
    func requestRide(pickup: RideLocationPoint, dropoff: RideLocationPoint?) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let ride = Ride(
                    clientId: currentUserId,
                    pickup: pickup,
                    dropoff: dropoff,
                    status: .requested
                )
                
                let createdRide = try await repo.create(ride)
                await MainActor.run {
                    self.activeRide = createdRide
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to request ride: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Cancel the active ride
    func cancelActiveRide() {
        guard var ride = activeRide else { return }
        
        isLoading = true
        
        Task {
            do {
                ride = ride.withStatus(.cancelled)
                try await repo.update(ride)
                await MainActor.run {
                    self.activeRide = nil
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel ride: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Simulate progression to next status (demo only)
    func simulateNextStatus() {
        guard var ride = activeRide else { return }
        guard let nextStatus = ride.status.nextStatus else {
            // Ride is complete
            history.insert(ride, at: 0)
            activeRide = nil
            return
        }
        
        Task {
            do {
                ride = ride.withStatus(nextStatus)
                
                // Assign demo driver when status becomes driverAssigned
                if nextStatus == .driverAssigned && ride.driverId == nil {
                    ride = ride.withDriver("driver-demo")
                }
                
                try await repo.update(ride)
                
                await MainActor.run {
                    if nextStatus == .completed {
                        self.history.insert(ride, at: 0)
                        self.activeRide = nil
                    } else {
                        self.activeRide = ride
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update ride: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Load ride history
    func loadHistory() {
        Task {
            do {
                let rides = try await repo.historyForClient(id: currentUserId)
                await MainActor.run {
                    self.history = rides
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load history: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Check if there's an active ride
    var hasActiveRide: Bool {
        activeRide != nil
    }
}
