//
//  AppError.swift
//  bicitaxi-conductor
//
//  Centralized error handling for the conductor app
//  Provides typed errors for better debugging and user feedback
//

import Foundation

/// Centralized error types for the Bici Taxi conductor app
enum AppError: LocalizedError, Equatable {
    
    // MARK: - Authentication Errors
    
    case authenticationFailed(String)
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case sessionExpired
    case signOutFailed
    
    // MARK: - Network Errors
    
    case networkUnavailable
    case requestTimeout
    case serverError(Int)
    case invalidResponse
    
    // MARK: - Ride Errors
    
    case rideCreationFailed
    case rideNotFound
    case rideUpdateFailed
    case rideAcceptFailed
    case rideAlreadyTaken
    case rideCancellationFailed
    
    // MARK: - Driver Errors
    
    case driverNotVerified
    case driverOffline
    case driverLicenseExpired
    
    // MARK: - Location Errors
    
    case locationPermissionDenied
    case locationUnavailable
    case geocodingFailed
    
    // MARK: - Validation Errors
    
    case invalidEmail
    case invalidPhoneNumber
    case invalidLicenseNumber
    case emptyRequiredField(String)
    
    // MARK: - Generic
    
    case unknown(String)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let message):
            return "Error de autenticación: \(message)"
        case .invalidCredentials:
            return "Email o contraseña incorrectos"
        case .userNotFound:
            return "Conductor no encontrado"
        case .emailAlreadyInUse:
            return "Este email ya está registrado"
        case .weakPassword:
            return "La contraseña es muy débil"
        case .sessionExpired:
            return "Tu sesión ha expirado. Por favor inicia sesión nuevamente"
        case .signOutFailed:
            return "Error al cerrar sesión"
            
        // Network
        case .networkUnavailable:
            return "Sin conexión a internet"
        case .requestTimeout:
            return "La solicitud tardó demasiado. Intenta nuevamente"
        case .serverError(let code):
            return "Error del servidor (código: \(code))"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
            
        // Ride
        case .rideCreationFailed:
            return "No se pudo crear el viaje"
        case .rideNotFound:
            return "Viaje no encontrado"
        case .rideUpdateFailed:
            return "No se pudo actualizar el viaje"
        case .rideAcceptFailed:
            return "No se pudo aceptar el viaje"
        case .rideAlreadyTaken:
            return "Este viaje ya fue tomado por otro conductor"
        case .rideCancellationFailed:
            return "No se pudo cancelar el viaje"
            
        // Driver
        case .driverNotVerified:
            return "Tu cuenta de conductor no está verificada"
        case .driverOffline:
            return "Debes estar en línea para aceptar viajes"
        case .driverLicenseExpired:
            return "Tu licencia ha expirado"
            
        // Location
        case .locationPermissionDenied:
            return "Permiso de ubicación denegado. Habilítalo en Configuración"
        case .locationUnavailable:
            return "No se pudo obtener tu ubicación"
        case .geocodingFailed:
            return "No se pudo obtener la dirección"
            
        // Validation
        case .invalidEmail:
            return "Email inválido"
        case .invalidPhoneNumber:
            return "Número de teléfono inválido"
        case .invalidLicenseNumber:
            return "Número de licencia inválido"
        case .emptyRequiredField(let field):
            return "\(field) es requerido"
            
        // Generic
        case .unknown(let message):
            return message
        }
    }
    
    /// User-friendly message for display in alerts
    var userMessage: String {
        errorDescription ?? "Ocurrió un error inesperado"
    }
    
    /// Whether the user should retry the action
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError, .rideAlreadyTaken:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Conversion

extension AppError {
    /// Create AppError from generic Error
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
