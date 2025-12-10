//
//  AuthManager.swift
//  bicitaxi-conductor
//
//  Authentication state management for Bici Taxi Conductor
//

import SwiftUI
import Combine
import AuthenticationServices

/// User authentication state
enum AuthState: Equatable {
    case unauthenticated
    case guest
    case authenticated(Driver)
}

/// Driver model for authentication
struct Driver: Equatable, Identifiable {
    let id: String
    let name: String
    let email: String
    let photoURL: URL?
    var licenseNumber: String?
    var vehicleInfo: String?
    
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages authentication state for the conductor app
@MainActor
class AuthManager: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Sign In with Apple
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email ?? "apple@driver.com"
                
                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                let driver = Driver(
                    id: userId,
                    name: displayName.isEmpty ? "Conductor Apple" : displayName,
                    email: email,
                    photoURL: nil
                )
                
                withAnimation {
                    authState = .authenticated(driver)
                }
            }
        case .failure(let error):
            errorMessage = "Error al iniciar sesión con Apple: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In with Google (Stub)
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Google Sign-In SDK integration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.errorMessage = "Google Sign-In próximamente"
            self?.isLoading = false
        }
    }
    
    // MARK: - Email/Password Sign In
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor ingresa email y contraseña"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Firebase Auth or backend authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            let driver = Driver(
                id: UUID().uuidString,
                name: "Conductor",
                email: email,
                photoURL: nil
            )
            
            withAnimation {
                self?.authState = .authenticated(driver)
            }
            self?.isLoading = false
        }
    }
    
    // MARK: - Registration
    
    func register(name: String, email: String, password: String, phone: String, licenseNumber: String) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor completa todos los campos"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Firebase Auth or backend registration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            let driver = Driver(
                id: UUID().uuidString,
                name: name,
                email: email,
                photoURL: nil,
                licenseNumber: licenseNumber
            )
            
            withAnimation {
                self?.authState = .authenticated(driver)
            }
            self?.isLoading = false
        }
    }
    
    // MARK: - Continue as Guest
    
    func continueAsGuest() {
        withAnimation {
            authState = .guest
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        withAnimation {
            authState = .unauthenticated
        }
    }
}
