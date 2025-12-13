//
//  AuthManager.swift
//  bicitaxi
//
//  Authentication state management for Bici Taxi
//

import SwiftUI
import Combine
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore


// User model is defined in Models/User.swift

/// User authentication state
enum AuthState: Equatable {
    case unauthenticated
    case guest
    case authenticated(User)
}


/// Manages authentication state for the app
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
                        // Fetch user details from Firestore
                        self.fetchUser(userId: user.uid)
                    }
                } else {
                    self.authState = .unauthenticated
                }
            }
        }
    }
    
    private func fetchUser(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let data = snapshot?.data(),
               let id = data["id"] as? String,
               let name = data["name"] as? String,
               let email = data["email"] as? String {
                
                let user = User(id: id, name: name, email: email, photoURL: nil)
                withAnimation {
                    self.authState = .authenticated(user)
                }
            } else {
                // Fallback if user doc doesn't exist (shouldn't happen if registered correctly)
                // Or maybe create one? using basic info
                 let user = User(id: userId, name: "Usuario", email: Auth.auth().currentUser?.email ?? "", photoURL: nil)
                 withAnimation {
                     self.authState = .authenticated(user)
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
                // This requires nonce handling and sending token to Firebase
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
                 // AuthState listener will handle the update
             }
        }
    }
    
    // MARK: - Registration
    
    func register(name: String, email: String, password: String, phone: String) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
             errorMessage = "Por favor completa todos los campos"
             return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ DEBUG: Auth Error: \(error)")
                    if let nsError = error as NSError? {
                         print("❌ DEBUG: Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)")
                    }
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let userId = result?.user.uid else {
                    self?.isLoading = false
                    return
                }
                
                // Create User Document
                let userData: [String: Any] = [
                    "id": userId,
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "role": "client",
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                self?.db.collection("users").document(userId).setData(userData) { error in
                    Task { @MainActor in
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = "Error al guardar perfil: \(error.localizedDescription)"
                        }
                        // AuthState listener will pick up the user
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
    
    // MARK: - Profile Management
    
    func updateProfile(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
                if case .authenticated(let user) = self?.authState {
                    let updatedUser = User(id: user.id, name: name, email: user.email, photoURL: user.photoURL)
                    self?.authState = .authenticated(updatedUser)
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
        
        // Update Password directly (requires recent login)
        user.updatePassword(to: new) { error in
            Task { @MainActor in
                self.isLoading = false
                if let error = error {
                    // Check for "requires recent login" error specifically to give better feedback?
                    // For now, just pass the error.
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
            // AuthState listener will handle unauthenticated
        } catch {
            errorMessage = "Error al cerrar sesión: \(error.localizedDescription)"
        }
    }
}
