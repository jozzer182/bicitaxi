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
    case history = 1
    case profile = 2
    
    var id: Int { rawValue }
    
    /// Display title for the tab
    var title: String {
        switch self {
        case .map: return "Mapa"
        case .history: return "Historial"
        case .profile: return "Perfil"
        }
    }
    
    /// SF Symbol name for the tab icon
    var systemImage: String {
        switch self {
        case .map: return "map.fill"
        case .history: return "clock.arrow.circlepath"
        case .profile: return "person.fill"
        }
    }
    
    /// Accessibility label for the tab
    var accessibilityLabel: String {
        switch self {
        case .map: return "Pestaña de mapa"
        case .history: return "Pestaña de historial"
        case .profile: return "Pestaña de perfil"
        }
    }
    
    /// Accessibility hint for the tab
    var accessibilityHint: String {
        switch self {
        case .map: return "Muestra el mapa con solicitudes de viaje"
        case .history: return "Muestra tu historial de viajes"
        case .profile: return "Muestra tu perfil y configuración"
        }
    }
}
