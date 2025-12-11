//
//  AuthServiceProtocol.swift
//  bicitaxi-conductor
//
//  Protocol for authentication service abstraction
//  Allows swapping between mock and Firebase auth implementations
//

import Foundation
import AuthenticationServices

/// Result of an authentication operation
enum AuthResult {
    case success(Driver)
    case failure(AppError)
}

/// Protocol defining authentication operations for conductors
/// Implement with Firebase Auth when integrated
protocol AuthServiceProtocol: AnyObject {
    
    // MARK: - Properties
    
    /// Current authenticated driver (nil if not authenticated)
    var currentDriver: Driver? { get }
    
    /// Whether a driver is currently signed in
    var isAuthenticated: Bool { get }
    
    // MARK: - Sign In Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async -> AuthResult
    
    /// Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async -> AuthResult
    
    /// Sign in with Google
    func signInWithGoogle(idToken: String, accessToken: String) async -> AuthResult
    
    // MARK: - Registration
    
    /// Register a new driver with email and password
    func register(name: String, email: String, password: String, licenseNumber: String?) async -> AuthResult
    
    // MARK: - Session Management
    
    /// Sign out the current driver
    func signOut() async throws
    
    /// Refresh the current driver's session
    func refreshSession() async throws
    
    /// Delete the current driver's account
    func deleteAccount() async throws
    
    // MARK: - Password Management
    
    /// Send password reset email
    func sendPasswordResetEmail(to email: String) async throws
    
    /// Update the current driver's password
    func updatePassword(currentPassword: String, newPassword: String) async throws
    
    // MARK: - Profile Management
    
    /// Update the current driver's profile
    func updateProfile(name: String?, photoURL: URL?, vehicleInfo: String?) async throws
    
    /// Update driver's online status
    func updateOnlineStatus(isOnline: Bool) async throws
}

// MARK: - Mock Implementation

/// Mock authentication service for development and testing
/// Replace with FirebaseAuthService when Firebase is integrated
final class MockAuthService: AuthServiceProtocol {
    
    private(set) var currentDriver: Driver?
    
    var isAuthenticated: Bool {
        currentDriver != nil
    }
    
    func signIn(email: String, password: String) async -> AuthResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Demo authentication - always succeeds
        let driver = Driver(
            id: UUID().uuidString,
            name: "Conductor",
            email: email,
            isOnline: true
        )
        currentDriver = driver
        return .success(driver)
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async -> AuthResult {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let driver = Driver(
            id: credential.user,
            name: displayName.isEmpty ? "Conductor Apple" : displayName,
            email: credential.email ?? "apple@driver.com",
            isOnline: true
        )
        currentDriver = driver
        return .success(driver)
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) async -> AuthResult {
        // TODO: Implement with Google Sign-In SDK
        return .failure(.unknown("Google Sign-In próximamente"))
    }
    
    func register(name: String, email: String, password: String, licenseNumber: String?) async -> AuthResult {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let driver = Driver(
            id: UUID().uuidString,
            name: name,
            email: email,
            licenseNumber: licenseNumber,
            isOnline: false,
            isVerified: false
        )
        currentDriver = driver
        return .success(driver)
    }
    
    func signOut() async throws {
        currentDriver = nil
    }
    
    func refreshSession() async throws {
        // No-op for mock
    }
    
    func deleteAccount() async throws {
        currentDriver = nil
    }
    
    func sendPasswordResetEmail(to email: String) async throws {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // No-op for mock
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // No-op for mock
    }
    
    func updateProfile(name: String?, photoURL: URL?, vehicleInfo: String?) async throws {
        guard var driver = currentDriver else {
            throw AppError.userNotFound
        }
        
        if let name = name {
            driver.name = name
        }
        if let photoURL = photoURL {
            driver.photoURL = photoURL
        }
        if let vehicleInfo = vehicleInfo {
            driver.vehicleInfo = vehicleInfo
        }
        
        currentDriver = driver
    }
    
    func updateOnlineStatus(isOnline: Bool) async throws {
        guard var driver = currentDriver else {
            throw AppError.userNotFound
        }
        
        driver.isOnline = isOnline
        currentDriver = driver
    }
}
