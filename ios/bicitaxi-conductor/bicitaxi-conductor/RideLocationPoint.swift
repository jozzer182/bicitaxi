//
//  RideLocationPoint.swift
//  bicitaxi-conductor
//
//  Location point for ride pickup/dropoff
//

import Foundation
import CoreLocation

/// Represents a location point in a ride
struct RideLocationPoint: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var address: String?
    
    /// Initialize from CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D, address: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
    
    /// Initialize with raw values
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
    
    /// Convert to CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Short display string
    var shortDescription: String {
        if let address = address, !address.isEmpty {
            return address
        }
        return String(format: "%.4f, %.4f", latitude, longitude)
    }
}
