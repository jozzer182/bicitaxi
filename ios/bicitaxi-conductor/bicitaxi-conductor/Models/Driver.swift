//
//  Driver.swift
//  bicitaxi-conductor
//
//  Driver model for conductor app - Firebase ready
//

import Foundation

/// Represents an authenticated driver in the Bici Taxi conductor app
/// Ready for Firestore serialization when Firebase is integrated
struct Driver: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Unique driver identifier (Firebase UID when integrated)
    let id: String
    
    /// Driver's display name
    var name: String
    
    /// Driver's email address
    let email: String
    
    /// Optional profile photo URL
    var photoURL: URL?
    
    /// Driver's phone number (required for contact)
    var phone: String?
    
    /// Driver's license number (for verification)
    var licenseNumber: String?
    
    /// Vehicle information (type, color, plate)
    var vehicleInfo: String?
    
    /// Driver's current availability status
    var isOnline: Bool
    
    /// Driver rating (1-5 stars)
    var rating: Double?
    
    /// Total completed rides count
    var completedRidesCount: Int
    
    /// Account creation timestamp
    var createdAt: Date
    
    /// Last profile update timestamp
    var updatedAt: Date
    
    /// Driver verification status
    var isVerified: Bool
    
    // MARK: - Initialization
    
    init(
        id: String,
        name: String,
        email: String,
        photoURL: URL? = nil,
        phone: String? = nil,
        licenseNumber: String? = nil,
        vehicleInfo: String? = nil,
        isOnline: Bool = false,
        rating: Double? = nil,
        completedRidesCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isVerified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.vehicleInfo = vehicleInfo
        self.isOnline = isOnline
        self.rating = rating
        self.completedRidesCount = completedRidesCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isVerified = isVerified
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable (Firestore ready)
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case photoURL = "photo_url"
        case phone
        case licenseNumber = "license_number"
        case vehicleInfo = "vehicle_info"
        case isOnline = "is_online"
        case rating
        case completedRidesCount = "completed_rides_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isVerified = "is_verified"
    }
    
    // MARK: - Firestore Serialization
    // TODO: Implement when Firebase is integrated
    
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "is_online": isOnline,
            "completed_rides_count": completedRidesCount,
            "created_at": createdAt.timeIntervalSince1970 * 1000,
            "updated_at": updatedAt.timeIntervalSince1970 * 1000,
            "is_verified": isVerified
        ]
        
        if let photoURL = photoURL {
            dict["photo_url"] = photoURL.absoluteString
        }
        
        if let phone = phone {
            dict["phone"] = phone
        }
        
        if let licenseNumber = licenseNumber {
            dict["license_number"] = licenseNumber
        }
        
        if let vehicleInfo = vehicleInfo {
            dict["vehicle_info"] = vehicleInfo
        }
        
        if let rating = rating {
            dict["rating"] = rating
        }
        
        return dict
    }
    
    /// Create from Firestore document
    static func fromDictionary(_ dict: [String: Any], id: String) -> Driver? {
        guard let name = dict["name"] as? String,
              let email = dict["email"] as? String else {
            return nil
        }
        
        let photoURLString = dict["photo_url"] as? String
        let photoURL = photoURLString.flatMap { URL(string: $0) }
        
        let createdAtMs = dict["created_at"] as? Double ?? Date().timeIntervalSince1970 * 1000
        let updatedAtMs = dict["updated_at"] as? Double ?? Date().timeIntervalSince1970 * 1000
        
        return Driver(
            id: id,
            name: name,
            email: email,
            photoURL: photoURL,
            phone: dict["phone"] as? String,
            licenseNumber: dict["license_number"] as? String,
            vehicleInfo: dict["vehicle_info"] as? String,
            isOnline: dict["is_online"] as? Bool ?? false,
            rating: dict["rating"] as? Double,
            completedRidesCount: dict["completed_rides_count"] as? Int ?? 0,
            createdAt: Date(timeIntervalSince1970: createdAtMs / 1000),
            updatedAt: Date(timeIntervalSince1970: updatedAtMs / 1000),
            isVerified: dict["is_verified"] as? Bool ?? false
        )
    }
}

// MARK: - Demo Data

extension Driver {
    /// Demo driver for testing
    static let demo = Driver(
        id: "driver-demo",
        name: "Conductor Demo",
        email: "conductor@demo.com",
        licenseNumber: "ABC123",
        vehicleInfo: "Bicicleta Azul",
        isOnline: true,
        rating: 4.8,
        completedRidesCount: 150,
        isVerified: true
    )
}
