//
//  DriverLocationTracker.swift
//  bicitaxi-conductor
//
//  Smart GPS location tracker for conductors.
//  Implements intelligent location publishing to reduce Firebase writes.
//

import Foundation
import CoreLocation
import Combine

/// Smart GPS location tracker for conductors.
///
/// Implements intelligent location publishing to reduce Firebase writes:
/// - Samples GPS every 30 seconds locally
/// - Maintains rolling buffer of last 3 positions
/// - Only publishes to Firebase if current position differs >3m from buffer average
@MainActor
class DriverLocationTracker: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isTracking: Bool = false
    @Published var lastPublishedLocation: CLLocationCoordinate2D?
    
    // MARK: - Private Properties
    
    private let requestService: RequestService
    private let locationManager = CLLocationManager()
    
    private var locationTimer: Timer?
    private var activeCellId: String?
    private var activeRequestId: String?
    
    // Rolling buffer of recent positions for smart filtering
    private var recentPositions: [CLLocation] = []
    private let bufferSize = 3
    private let movementThresholdMeters: Double = 3.0
    private let samplingInterval: TimeInterval = 30
    
    // MARK: - Initialization
    
    init(requestService: RequestService) {
        self.requestService = requestService
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Public Methods
    
    /// Start tracking driver location for a request.
    /// Call this when driver accepts a request.
    func startTracking(cellId: String, requestId: String) {
        if isTracking {
            stopTracking()
        }
        
        activeCellId = cellId
        activeRequestId = requestId
        recentPositions.removeAll()
        isTracking = true
        
        print("📍 DriverLocationTracker: Started tracking for request \(requestId)")
        
        // Request location permission if needed
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Immediately sample first position
        sampleLocation()
        
        // Start periodic sampling
        locationTimer = Timer.scheduledTimer(withTimeInterval: samplingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleLocation()
            }
        }
    }
    
    /// Stop tracking driver location.
    /// Call this when request is completed or cancelled.
    func stopTracking() {
        locationTimer?.invalidate()
        locationTimer = nil
        activeCellId = nil
        activeRequestId = nil
        recentPositions.removeAll()
        isTracking = false
        lastPublishedLocation = nil
        
        print("📍 DriverLocationTracker: Stopped tracking")
    }
    
    // MARK: - Private Methods
    
    /// Sample current location and publish if movement is significant.
    private func sampleLocation() {
        guard isTracking, activeCellId != nil, activeRequestId != nil else { return }
        
        locationManager.requestLocation()
    }
    
    /// Determine if position should be published based on movement from buffer average.
    private func shouldPublish(current: CLLocation) -> Bool {
        // Always publish first position
        guard !recentPositions.isEmpty else { return true }
        
        // Calculate average of recent positions
        var avgLat: Double = 0
        var avgLng: Double = 0
        for pos in recentPositions {
            avgLat += pos.coordinate.latitude
            avgLng += pos.coordinate.longitude
        }
        avgLat /= Double(recentPositions.count)
        avgLng /= Double(recentPositions.count)
        
        let avgLocation = CLLocation(latitude: avgLat, longitude: avgLng)
        
        // Calculate distance from average
        let distance = current.distance(from: avgLocation)
        
        // Only publish if movement exceeds threshold
        return distance > movementThresholdMeters
    }
    
    /// Publish location to Firebase.
    private func publishLocation(_ location: CLLocation) async {
        guard let cellId = activeCellId, let requestId = activeRequestId else { return }
        
        await requestService.updateDriverLocation(
            cellId: cellId,
            requestId: requestId,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )
        
        lastPublishedLocation = location.coordinate
        print("📍 DriverLocationTracker: Published location (\(location.coordinate.latitude), \(location.coordinate.longitude))")
    }
}

// MARK: - CLLocationManagerDelegate

extension DriverLocationTracker: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            let shouldPublishNow = self.shouldPublish(current: location)
            
            // Add to buffer
            self.recentPositions.append(location)
            if self.recentPositions.count > self.bufferSize {
                self.recentPositions.removeFirst()
            }
            
            if shouldPublishNow {
                await self.publishLocation(location)
            } else {
                print("📍 DriverLocationTracker: Skipping publish (minimal movement)")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ DriverLocationTracker: Location error: \(error)")
    }
}
