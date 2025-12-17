//
//  DriverRideViewModel.swift
//  bicitaxi-conductor
//
//  View model for driver ride operations
//

import Foundation
import SwiftUI
import Combine

/// View model for driver ride flow
@MainActor
class DriverRideViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Pending ride requests available to accept
    @Published var pendingRides: [Ride] = []
    
    /// Current active ride (if any)
    @Published var activeRide: Ride?
    
    /// Completed rides history
    @Published var completedRides: [Ride] = []
    
    /// Driver online status
    @Published var isOnline: Bool = false
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let repo: InMemoryRideRepository
    private let presenceService = PresenceService()
    private let currentDriverId = "driver-demo"
    private var hasGeneratedDummyRides = false
    
    /// Callbacks to get current location (set from view)
    private var getLatitude: (() -> Double)?
    private var getLongitude: (() -> Double)?
    
    // MARK: - Computed Properties
    
    /// Total earnings from completed rides (Colombian Pesos)
    var totalEarnings: Int {
        completedRides.reduce(0) { total, ride in
            total + ride.estimatedFare
        }
    }
    
    // MARK: - Initialization
    
    init(repo: InMemoryRideRepository) {
        self.repo = repo
    }
    
    // MARK: - Public Methods
    
    /// Initialize with dummy pending rides
    func initializeWithDummyRides(around center: RideLocationPoint) {
        guard !hasGeneratedDummyRides else { return }
        hasGeneratedDummyRides = true
        
        Task {
            await repo.generateDummyRides(around: center)
            await loadPendingRidesAsync()
        }
    }
    
    /// Clear all pending rides (for when mock data is disabled)
    func clearPendingRides() {
        pendingRides = []
        hasGeneratedDummyRides = false
    }
    
    /// Load pending rides
    func loadPendingRides() {
        Task {
            await loadPendingRidesAsync()
        }
    }
    
    private func loadPendingRidesAsync() async {
        guard isOnline else {
            await MainActor.run { pendingRides = [] }
            return
        }
        
        do {
            let rides = try await repo.pendingRides()
            await MainActor.run { self.pendingRides = rides }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load pending rides: \(error.localizedDescription)"
            }
        }
    }
    
    /// Accept a ride request
    func acceptRide(_ ride: Ride) {
        isLoading = true
        
        Task {
            do {
                var updatedRide = ride
                    .withDriver(currentDriverId)
                    .withStatus(.driverAssigned)
                
                try await repo.update(updatedRide)
                
                await MainActor.run {
                    self.activeRide = updatedRide
                    self.pendingRides.removeAll { $0.id == ride.id }
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to accept ride: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Start the active ride (driver arrived, begin trip)
    func startRide() {
        guard var ride = activeRide else { return }
        
        isLoading = true
        
        Task {
            do {
                ride = ride.withStatus(.inProgress)
                try await repo.update(ride)
                await MainActor.run {
                    self.activeRide = ride
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start ride: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Mark driver as arriving to pickup
    func markArriving() {
        guard var ride = activeRide else { return }
        
        Task {
            do {
                ride = ride.withStatus(.driverArriving)
                try await repo.update(ride)
                await MainActor.run { self.activeRide = ride }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update ride: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Finish the active ride
    func finishRide() {
        guard var ride = activeRide else { return }
        
        isLoading = true
        
        Task {
            do {
                ride = ride.withStatus(.completed)
                try await repo.update(ride)
                
                await MainActor.run {
                    self.completedRides.insert(ride, at: 0)
                    self.activeRide = nil
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to finish ride: \(error.localizedDescription)"
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
    
    /// Load completed rides history
    func loadCompletedRides() {
        Task {
            do {
                let rides = try await repo.historyForDriver(id: currentDriverId)
                await MainActor.run { self.completedRides = rides }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load history: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Location Callbacks
    
    /// Set location callbacks for presence updates
    func setLocationCallbacks(
        getLatitude: @escaping () -> Double,
        getLongitude: @escaping () -> Double
    ) {
        self.getLatitude = getLatitude
        self.getLongitude = getLongitude
    }
    
    /// Toggle online status and manage presence
    func toggleOnline() {
        Task {
            if isOnline {
                // Going offline
                await goOffline()
            } else {
                // Going online
                await goOnline()
            }
        }
    }
    
    /// Go online and start presence heartbeat
    private func goOnline() async {
        guard let getLat = getLatitude, let getLng = getLongitude else {
            print("⚠️ DriverRideViewModel: Location callbacks not set, cannot go online")
            errorMessage = "No se pudo obtener tu ubicación"
            return
        }
        
        isOnline = true
        
        // Start presence heartbeat
        presenceService.startHeartbeat(
            getLatitude: getLat,
            getLongitude: getLng,
            getActiveRideId: { [weak self] in self?.activeRide?.id }
        )
        
        // Load pending rides
        await loadPendingRidesAsync()
    }
    
    /// Go offline and stop presence
    private func goOffline() async {
        isOnline = false
        pendingRides = []
        await presenceService.goOffline()
    }
    
    /// Check if there's an active ride
    var hasActiveRide: Bool {
        activeRide != nil
    }
}
