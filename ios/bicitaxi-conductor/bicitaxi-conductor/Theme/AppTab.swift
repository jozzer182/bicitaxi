//
//  AppTab.swift
//  bicitaxi-conductor
//
//  Tab model for Liquid Glass navigation
//

import SwiftUI

/// Represents the tabs in the Bici Taxi Conductor (driver) app
enum AppTab: Int, CaseIterable, Identifiable {
    case map = 0
    case activeRide = 1
    case earnings = 2
    case profile = 3
    
    var id: Int { rawValue }
    
    /// Display title for the tab
    var title: String {
        switch self {
        case .map: return "Mapa"
        case .activeRide: return "Viaje"
        case .earnings: return "Ganancias"
        case .profile: return "Perfil"
        }
    }
    
    /// SF Symbol name for the tab icon
    var systemImage: String {
        switch self {
        case .map: return "map.fill"
        case .activeRide: return "bicycle"
        case .earnings: return "dollarsign.circle.fill"
        case .profile: return "person.fill"
        }
    }
    
    /// Accessibility label for the tab
    var accessibilityLabel: String {
        switch self {
        case .map: return "Pestaña de mapa"
        case .activeRide: return "Pestaña de viaje activo"
        case .earnings: return "Pestaña de ganancias"
        case .profile: return "Pestaña de perfil"
        }
    }
    
    /// Accessibility hint for the tab
    var accessibilityHint: String {
        switch self {
        case .map: return "Muestra el mapa con solicitudes de viaje"
        case .activeRide: return "Muestra tu viaje activo actual"
        case .earnings: return "Muestra tu resumen de ganancias"
        case .profile: return "Muestra tu perfil y configuración"
        }
    }
}
