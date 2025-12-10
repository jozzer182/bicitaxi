//
//  AppTab.swift
//  bicitaxi
//
//  Tab model for Liquid Glass navigation
//

import SwiftUI

/// Represents the tabs in the Bici Taxi client app
enum AppTab: Int, CaseIterable, Identifiable {
    case map = 0
    case activeRide = 1
    case profile = 2
    
    var id: Int { rawValue }
    
    /// Display title for the tab
    var title: String {
        switch self {
        case .map: return "Mapa"
        case .activeRide: return "Viaje"
        case .profile: return "Perfil"
        }
    }
    
    /// SF Symbol name for the tab icon
    var systemImage: String {
        switch self {
        case .map: return "map.fill"
        case .activeRide: return "bicycle"
        case .profile: return "person.fill"
        }
    }
    
    /// Accessibility label for the tab
    var accessibilityLabel: String {
        switch self {
        case .map: return "Pestaña de mapa"
        case .activeRide: return "Pestaña de viaje activo"
        case .profile: return "Pestaña de perfil"
        }
    }
    
    /// Accessibility hint for the tab
    var accessibilityHint: String {
        switch self {
        case .map: return "Muestra el mapa para solicitar viajes"
        case .activeRide: return "Muestra tu viaje actual"
        case .profile: return "Muestra tu perfil y configuración"
        }
    }
}
