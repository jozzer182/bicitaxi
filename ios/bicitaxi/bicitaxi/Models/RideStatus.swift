//
//  RideStatus.swift
//  bicitaxi
//
//  Ride lifecycle status enum
//

import Foundation

/// Represents the lifecycle status of a ride
enum RideStatus: String, Codable, CaseIterable {
    case requested = "requested"
    case searchingDriver = "searching_driver"
    case driverAssigned = "driver_assigned"
    case driverArriving = "driver_arriving"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    /// Human-readable display text
    var displayText: String {
        switch self {
        case .requested: return "Solicitando viaje..."
        case .searchingDriver: return "Buscando conductor..."
        case .driverAssigned: return "¡Conductor asignado!"
        case .driverArriving: return "El conductor está en camino"
        case .inProgress: return "Viaje en progreso"
        case .completed: return "Viaje completado"
        case .cancelled: return "Viaje cancelado"
        }
    }
    
    /// SF Symbol icon for the status
    var iconName: String {
        switch self {
        case .requested: return "clock.fill"
        case .searchingDriver: return "magnifyingglass"
        case .driverAssigned: return "checkmark.circle.fill"
        case .driverArriving: return "bicycle"
        case .inProgress: return "figure.outdoor.cycle"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    /// Whether the ride is still active (not finished)
    var isActive: Bool {
        switch self {
        case .requested, .searchingDriver, .driverAssigned, .driverArriving, .inProgress:
            return true
        case .completed, .cancelled:
            return false
        }
    }
    
    /// Next status in the progression (for simulation)
    var nextStatus: RideStatus? {
        switch self {
        case .requested: return .searchingDriver
        case .searchingDriver: return .driverAssigned
        case .driverAssigned: return .driverArriving
        case .driverArriving: return .inProgress
        case .inProgress: return .completed
        case .completed, .cancelled: return nil
        }
    }
}
