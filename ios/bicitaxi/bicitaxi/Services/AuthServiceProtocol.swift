//
//  AuthServiceProtocol.swift
//  bicitaxi
//
//  Protocol for authentication service abstraction
//  Allows swapping between mock and Firebase auth implementations
//

import Foundation
import AuthenticationServices

/// Result of an authentication operation
enum AuthResult {
    case success(User)
    case failure(AppError)
}

/// Protocol defining authentication operations
/// Implement with Firebase Auth when integrated
protocol AuthServiceProtocol: AnyObject {
    
    // MARK: - Properties
    
    /// Current authenticated user (nil if not authenticated)
    var currentUser: User? { get }
    
    /// Whether a user is currently signed in
    var isAuthenticated: Bool { get }
    
    // MARK: - Sign In Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async -> AuthResult
    
    /// Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async -> AuthResult
    
    /// Sign in with Google
    func signInWithGoogle(idToken: String, accessToken: String) async -> AuthResult
    
    // MARK: - Registration
    
    /// Register a new user with email and password
    func register(name: String, email: String, password: String) async -> AuthResult
    
    // MARK: - Session Management
    
    /// Sign out the current user
    func signOut() async throws
    
    /// Refresh the current user's session
    func refreshSession() async throws
    
    /// Delete the current user's account
    func deleteAccount() async throws
    
    // MARK: - Password Management
    
    /// Send password reset email
    func sendPasswordResetEmail(to email: String) async throws
    
    /// Update the current user's password
    func updatePassword(currentPassword: String, newPassword: String) async throws
    
    // MARK: - Profile Management
    
    /// Update the current user's profile
    func updateProfile(name: String?, photoURL: URL?) async throws
}

// MARK: - Mock Implementation

/// Mock authentication service for development and testing
/// Replace with FirebaseAuthService when Firebase is integrated
final class MockAuthService: AuthServiceProtocol {
    
    private(set) var currentUser: User?
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    func signIn(email: String, password: String) async -> AuthResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Demo authentication - always succeeds
        let user = User(
            id: UUID().uuidString,
            name: "Usuario",
            email: email
        )
        currentUser = user
        return .success(user)
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async -> AuthResult {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let user = User(
            id: credential.user,
            name: displayName.isEmpty ? "Usuario Apple" : displayName,
            email: credential.email ?? "apple@user.com"
        )
        currentUser = user
        return .success(user)
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) async -> AuthResult {
        // TODO: Implement with Google Sign-In SDK
        return .failure(.unknown("Google Sign-In próximamente"))
    }
    
    func register(name: String, email: String, password: String) async -> AuthResult {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let user = User(
            id: UUID().uuidString,
            name: name,
            email: email
        )
        currentUser = user
        return .success(user)
    }
    
    func signOut() async throws {
        currentUser = nil
    }
    
    func refreshSession() async throws {
        // No-op for mock
    }
    
    func deleteAccount() async throws {
        currentUser = nil
    }
    
    func sendPasswordResetEmail(to email: String) async throws {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // No-op for mock
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // No-op for mock
    }
    
    func updateProfile(name: String?, photoURL: URL?) async throws {
        guard var user = currentUser else {
            throw AppError.userNotFound
        }
        
        if let name = name {
            user.name = name
        }
        if let photoURL = photoURL {
            user.photoURL = photoURL
        }
        
        currentUser = user
    }
}
