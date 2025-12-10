//
//  LocationManager.swift
//  bicitaxi-conductor
//
//  Location service for tracking driver position
//

import Foundation
import CoreLocation
import Combine

/// Observable location manager for SwiftUI
@MainActor
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Current user coordinate
    @Published var currentCoordinate: CLLocationCoordinate2D?
    
    /// Whether location is currently being fetched
    @Published var isLocating: Bool = false
    
    /// Error message if location fails
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Request location permission (when in use)
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating location
    func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse || 
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        
        isLocating = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating location
    func stopUpdating() {
        isLocating = false
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.currentCoordinate = location.coordinate
            self.isLocating = false
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Unable to get location: \(error.localizedDescription)"
            self.isLocating = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdating()
            case .denied, .restricted:
                self.errorMessage = "Location permission denied. Enable it in Settings to see ride requests."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
