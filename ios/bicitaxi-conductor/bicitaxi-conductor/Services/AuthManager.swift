//
//  AuthManager.swift
//  bicitaxi-conductor
//
//  Authentication state management for Bici Taxi Conductor
//

import SwiftUI
import Combine
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore


// Driver model is defined in Models/Driver.swift

/// User authentication state
enum AuthState: Equatable {
    case unauthenticated
    case guest
    case authenticated(Driver)
}


/// Manages authentication state for the conductor app
@MainActor
class AuthManager: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        // Listen to Auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                if let user = user {
                    if user.isAnonymous {
                         self.authState = .guest
                    } else {
                        // Fetch driver details from Firestore
                        self.fetchDriver(userId: user.uid)
                    }
                } else {
                    self.authState = .unauthenticated
                }
            }
        }
    }
    
    private func fetchDriver(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let data = snapshot?.data() {
               let id = data["id"] as? String ?? userId
               let name = data["name"] as? String ?? "Conductor"
               let email = data["email"] as? String ?? ""
               let licenseNumber = data["licenseNumber"] as? String ?? ""
               // isOnline might need to be fetched or managed locally/separately
               let isOnline = data["isOnline"] as? Bool ?? false
               
                let driver = Driver(
                    id: id,
                    name: name,
                    email: email,
                    photoURL: nil,
                    licenseNumber: licenseNumber,
                    isOnline: isOnline
                )
                withAnimation {
                    self.authState = .authenticated(driver)
                }
            } else {
                // Fallback or handle missing profile
                 let driver = Driver(
                    id: userId,
                    name: "Conductor",
                    email: Auth.auth().currentUser?.email ?? "",
                    photoURL: nil,
                    licenseNumber: "",
                    isOnline: false
                 )
                 withAnimation {
                     self.authState = .authenticated(driver)
                 }
            }
        }
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let _ = authorization.credential as? ASAuthorizationAppleIDCredential {
                 // TODO: Implement proper Firebase Apple Sign-In
                 self.errorMessage = "Inicio de sesión con Apple requiere configuración backend adicional."
            }
        case .failure(let error):
            errorMessage = "Error al iniciar sesión con Apple: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        // TODO: Requires GoogleSignIn-iOS SDK
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
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
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
             Task { @MainActor in
                 self?.isLoading = false
                 if let error = error {
                     self?.errorMessage = error.localizedDescription
                     return
                 }
             }
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
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let userId = result?.user.uid else {
                    self?.isLoading = false
                    return
                }
                
                // Create Driver Document
                let userData: [String: Any] = [
                    "id": userId,
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "licenseNumber": licenseNumber,
                    "role": "driver",
                    "isOnline": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                self?.db.collection("users").document(userId).setData(userData) { error in
                    Task { @MainActor in
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = "Error al guardar perfil: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Continue as Guest
    
    func continueAsGuest() {
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] result, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error anónimo: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - App Persistence & Rehydration
    
    // MARK: - Profile Management
    
    func updateDriverProfile(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])))
            return
        }
        
        isLoading = true
        
        let updateData: [String: Any] = ["name": name]
        
        db.collection("users").document(userId).updateData(updateData) { [weak self] error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Update local state if authenticated
                if case .authenticated(let driver) = self?.authState {
                    let updatedDriver = Driver(
                        id: driver.id,
                        name: name,
                        email: driver.email,
                        photoURL: driver.photoURL,
                        licenseNumber: driver.licenseNumber,
                        isOnline: driver.isOnline
                    )
                    self?.authState = .authenticated(updatedDriver)
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Password Management
    
    func changePassword(new: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])))
            return
        }
        
        isLoading = true
        
        // Update Password directly
        user.updatePassword(to: new) { error in
            Task { @MainActor in
                self.isLoading = false
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Error al cerrar sesión: \(error.localizedDescription)"
        }
    }
}
