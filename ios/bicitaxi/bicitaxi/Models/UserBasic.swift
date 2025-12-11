//
//  UserBasic.swift
//  bicitaxi
//
//  Basic user information for rides
//  Matches Flutter app model for Firebase compatibility.
//

import Foundation

/// Basic user information for rides
/// This is a lightweight user reference used within Ride objects.
struct UserBasic: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var phone: String
    
    // MARK: - Firebase Serialization
    
    /// Convert to dictionary for Firestore.
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "phone": phone
        ]
    }
    
    /// Alias for toDictionary() - use this explicitly for Firebase operations.
    func toFirestore() -> [String: Any] {
        return toDictionary()
    }
    
    /// Create from dictionary.
    static func fromDictionary(_ dict: [String: Any]) -> UserBasic? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let phone = dict["phone"] as? String else {
            return nil
        }
        return UserBasic(id: id, name: name, phone: phone)
    }
    
    /// Alias for fromDictionary() - use this explicitly for Firebase operations.
    static func fromFirestore(_ dict: [String: Any], id documentId: String? = nil) -> UserBasic? {
        var data = dict
        if let documentId = documentId {
            data["id"] = documentId
        }
        return fromDictionary(data)
    }
    
    // MARK: - Firebase Constants
    
    /// Firebase collection name for users.
    static let collectionName = "users"
    
    // MARK: - Demo Data
    
    /// Default demo client user
    static let demoClient = UserBasic(
        id: "client-demo",
        name: "Demo Client",
        phone: "+1234567890"
    )
    
    /// Default demo driver user
    static let demoDriver = UserBasic(
        id: "driver-demo",
        name: "Demo Driver",
        phone: "+0987654321"
    )
}
