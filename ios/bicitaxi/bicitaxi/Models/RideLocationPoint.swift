//
//  RideLocationPoint.swift
//  bicitaxi
//
//  Location point for ride pickup/dropoff
//  Uses canonical field names (lat, lng) matching Flutter app.
//

import Foundation
import CoreLocation

/// Represents a location point in a ride
/// Uses 'latitude'/'longitude' internally but serializes to 'lat'/'lng' for Firebase.
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
    
    // MARK: - Firebase Serialization
    // Uses canonical field names (lat, lng) matching Flutter app.
    
    /// Convert to dictionary for Firestore with canonical field names.
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "lat": latitude,
            "lng": longitude
        ]
        if let address = address {
            dict["address"] = address
        }
        return dict
    }
    
    /// Alias for toDictionary() - use this explicitly for Firebase operations.
    func toFirestore() -> [String: Any] {
        return toDictionary()
    }
    
    /// Create from dictionary with canonical field names (lat, lng).
    static func fromDictionary(_ dict: [String: Any]) -> RideLocationPoint? {
        guard let lat = dict["lat"] as? Double,
              let lng = dict["lng"] as? Double else {
            return nil
        }
        return RideLocationPoint(
            latitude: lat,
            longitude: lng,
            address: dict["address"] as? String
        )
    }
    
    /// Alias for fromDictionary() - use this explicitly for Firebase operations.
    static func fromFirestore(_ dict: [String: Any]) -> RideLocationPoint? {
        return fromDictionary(dict)
    }
}
