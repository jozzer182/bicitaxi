//
//  User.swift
//  bicitaxi
//
//  User model for client app - Firebase ready
//

import Foundation

/// Represents an authenticated user in the Bici Taxi client app
/// Ready for Firestore serialization when Firebase is integrated
struct User: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Unique user identifier (Firebase UID when integrated)
    let id: String
    
    /// User's display name
    var name: String
    
    /// User's email address
    let email: String
    
    /// Optional profile photo URL
    var photoURL: URL?
    
    /// User's phone number (optional)
    var phone: String?
    
    /// Account creation timestamp
    var createdAt: Date
    
    /// Last profile update timestamp
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(
        id: String,
        name: String,
        email: String,
        photoURL: URL? = nil,
        phone: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.phone = phone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Equatable
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable (Firestore ready)
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case photoURL = "photo_url"
        case phone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Firestore Serialization
    // TODO: Implement when Firebase is integrated
    
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "created_at": createdAt.timeIntervalSince1970 * 1000,
            "updated_at": updatedAt.timeIntervalSince1970 * 1000
        ]
        
        if let photoURL = photoURL {
            dict["photo_url"] = photoURL.absoluteString
        }
        
        if let phone = phone {
            dict["phone"] = phone
        }
        
        return dict
    }
    
    /// Create from Firestore document
    static func fromDictionary(_ dict: [String: Any], id: String) -> User? {
        guard let name = dict["name"] as? String,
              let email = dict["email"] as? String else {
            return nil
        }
        
        let photoURLString = dict["photo_url"] as? String
        let photoURL = photoURLString.flatMap { URL(string: $0) }
        let phone = dict["phone"] as? String
        
        let createdAtMs = dict["created_at"] as? Double ?? Date().timeIntervalSince1970 * 1000
        let updatedAtMs = dict["updated_at"] as? Double ?? Date().timeIntervalSince1970 * 1000
        
        return User(
            id: id,
            name: name,
            email: email,
            photoURL: photoURL,
            phone: phone,
            createdAt: Date(timeIntervalSince1970: createdAtMs / 1000),
            updatedAt: Date(timeIntervalSince1970: updatedAtMs / 1000)
        )
    }
}

// MARK: - Demo Data

extension User {
    /// Demo user for testing
    static let demo = User(
        id: "client-demo",
        name: "Cliente Demo",
        email: "cliente@demo.com"
    )
}
