//
//  UserBasic.swift
//  bicitaxi-conductor
//
//  Basic user information for rides
//

import Foundation

/// Basic user information for rides
struct UserBasic: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var phone: String
    
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
