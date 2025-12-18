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
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift


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
    
    // Current nonce for Apple Sign-In (needed for Firebase)
    private var currentNonce: String?
    
    /// Generates a random nonce for Apple Sign-In
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    /// SHA256 hash of the nonce
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    /// Prepares and returns the nonce for Apple Sign-In request
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        print("🍎 [AppleSignIn] ========== SIGN IN WITH APPLE STARTED ==========")
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            print("🍎 [AppleSignIn] Authorization SUCCESS received")
            print("🍎 [AppleSignIn] Credential type: \(type(of: authorization.credential))")
            
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("🍎 [AppleSignIn] ✓ Got ASAuthorizationAppleIDCredential")
                print("🍎 [AppleSignIn] User ID: \(appleIDCredential.user)")
                print("🍎 [AppleSignIn] Email: \(appleIDCredential.email ?? "nil")")
                print("🍎 [AppleSignIn] Full Name: \(appleIDCredential.fullName?.givenName ?? "nil") \(appleIDCredential.fullName?.familyName ?? "nil")")
                print("🍎 [AppleSignIn] Authorization code present: \(appleIDCredential.authorizationCode != nil)")
                print("🍎 [AppleSignIn] Identity token present: \(appleIDCredential.identityToken != nil)")
                
                guard let nonce = currentNonce else {
                    print("❌ [AppleSignIn] CRITICAL: No nonce available! Was prepareAppleSignIn() called?")
                    errorMessage = "Error interno: intenta de nuevo"
                    isLoading = false
                    return
                }
                print("🍎 [AppleSignIn] ✓ Nonce available (length: \(nonce.count))")
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("❌ [AppleSignIn] CRITICAL: No identity token in credential")
                    errorMessage = "Error al obtener token de Apple"
                    isLoading = false
                    return
                }
                print("🍎 [AppleSignIn] ✓ Identity token obtained (size: \(appleIDToken.count) bytes)")
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("❌ [AppleSignIn] CRITICAL: Failed to decode token as UTF-8 string")
                    errorMessage = "Error al procesar token"
                    isLoading = false
                    return
                }
                print("🍎 [AppleSignIn] ✓ Token decoded to string (length: \(idTokenString.count))")
                print("🍎 [AppleSignIn] Token preview: \(String(idTokenString.prefix(50)))...")
                
                print("🍎 [AppleSignIn] Creating Firebase OAuthProvider credential...")
                // Create Firebase credential
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                print("🍎 [AppleSignIn] ✓ Firebase credential created")
                print("🍎 [AppleSignIn] Credential provider: \(credential.provider)")
                
                print("🍎 [AppleSignIn] Calling Firebase Auth.signIn(with: credential)...")
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    Task { @MainActor in
                        self?.isLoading = false
                        
                        if let error = error {
                            print("❌ [AppleSignIn] Firebase Auth FAILED!")
                            print("❌ [AppleSignIn] Error: \(error.localizedDescription)")
                            if let nsError = error as NSError? {
                                print("❌ [AppleSignIn] Domain: \(nsError.domain)")
                                print("❌ [AppleSignIn] Code: \(nsError.code)")
                                print("❌ [AppleSignIn] UserInfo: \(nsError.userInfo)")
                            }
                            self?.errorMessage = "Error: \(error.localizedDescription)"
                            return
                        }
                        
                        guard let user = authResult?.user else {
                            print("❌ [AppleSignIn] No user in auth result (but no error either)")
                            return
                        }
                        print("🍎 [AppleSignIn] ========== SUCCESS ==========")
                        print("🍎 [AppleSignIn] Firebase UID: \(user.uid)")
                        print("🍎 [AppleSignIn] Firebase Email: \(user.email ?? "nil")")
                        print("🍎 [AppleSignIn] Firebase Display Name: \(user.displayName ?? "nil")")
                        print("🍎 [AppleSignIn] Is Anonymous: \(user.isAnonymous)")
                        print("🍎 [AppleSignIn] Provider ID: \(user.providerID)")
                        
                        // Create/update driver document in Firestore
                        let displayName = [
                            appleIDCredential.fullName?.givenName,
                            appleIDCredential.fullName?.familyName
                        ].compactMap { $0 }.joined(separator: " ")
                        
                        print("🍎 [AppleSignIn] Saving driver to Firestore...")
                        let userData: [String: Any] = [
                            "id": user.uid,
                            "name": displayName.isEmpty ? "Conductor" : displayName,
                            "email": user.email ?? appleIDCredential.email ?? "",
                            "role": "driver",
                            "isOnline": false,
                            "updatedAt": FieldValue.serverTimestamp()
                        ]
                        print("🍎 [AppleSignIn] Driver data: \(userData)")
                        
                        self?.db.collection("users").document(user.uid).setData(userData, merge: true) { error in
                            if let error = error {
                                print("⚠️ [AppleSignIn] Firestore write FAILED: \(error.localizedDescription)")
                            } else {
                                print("🍎 [AppleSignIn] ✓ Firestore document saved successfully")
                            }
                        }
                        // AuthState listener will handle the UI update
                    }
                }
            } else {
                print("❌ [AppleSignIn] Credential is NOT ASAuthorizationAppleIDCredential")
                print("❌ [AppleSignIn] Actual type: \(type(of: authorization.credential))")
                isLoading = false
            }
        case .failure(let error):
            isLoading = false
            let nsError = error as NSError
            print("❌ [AppleSignIn] Authorization FAILED!")
            print("❌ [AppleSignIn] Error: \(error.localizedDescription)")
            print("❌ [AppleSignIn] Domain: \(nsError.domain)")
            print("❌ [AppleSignIn] Code: \(nsError.code)")
            
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                print("🍎 [AppleSignIn] User cancelled (code 1001)")
                // Don't show error for cancellation
            } else if nsError.code == ASAuthorizationError.failed.rawValue {
                print("❌ [AppleSignIn] Authorization failed (code 1000)")
                errorMessage = "La autorización falló. Verifica tu configuración."
            } else if nsError.code == ASAuthorizationError.invalidResponse.rawValue {
                print("❌ [AppleSignIn] Invalid response (code 1002)")
                errorMessage = "Respuesta inválida de Apple"
            } else if nsError.code == ASAuthorizationError.notHandled.rawValue {
                print("❌ [AppleSignIn] Not handled (code 1003)")
                errorMessage = "La solicitud no fue manejada"
            } else if nsError.code == ASAuthorizationError.notInteractive.rawValue {
                print("❌ [AppleSignIn] Not interactive (code 1004)")
                errorMessage = "Se requiere interacción del usuario"
            } else {
                print("❌ [AppleSignIn] Unknown error code: \(nsError.code)")
                errorMessage = "Error al iniciar sesión con Apple"
            }
        }
        print("🍎 [AppleSignIn] ========== END ==========")
    }

    
    // MARK: - Sign In with Google
    
    func signInWithGoogle() {
        print("🔵 [GoogleSignIn] ========== SIGN IN WITH GOOGLE STARTED ==========")
        isLoading = true
        errorMessage = nil
        
        // Get the client ID from the GoogleService-Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? getGoogleClientID() else {
            print("❌ [GoogleSignIn] No client ID found")
            errorMessage = "Configuración de Google Sign-In incompleta"
            isLoading = false
            return
        }
        print("🔵 [GoogleSignIn] Client ID: \(clientID.prefix(30))...")
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [GoogleSignIn] No root view controller found")
            errorMessage = "Error interno de configuración"
            isLoading = false
            return
        }
        print("🔵 [GoogleSignIn] Got root view controller")
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        print("🔵 [GoogleSignIn] Configuration set, calling signIn...")
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ [GoogleSignIn] Error: \(error.localizedDescription)")
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        print("🔵 [GoogleSignIn] User cancelled")
                    } else {
                        self?.errorMessage = "Error: \(error.localizedDescription)"
                    }
                    self?.isLoading = false
                    return
                }
                
                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    print("❌ [GoogleSignIn] No user or ID token")
                    self?.errorMessage = "Error al obtener token de Google"
                    self?.isLoading = false
                    return
                }
                
                print("🔵 [GoogleSignIn] ✓ Got Google user: \(user.profile?.name ?? "n/a")")
                print("🔵 [GoogleSignIn] ✓ Email: \(user.profile?.email ?? "n/a")")
                
                // Create Firebase credential
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                print("🔵 [GoogleSignIn] Created Firebase credential, signing in...")
                
                // Sign in with Firebase
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    print("🔵 [GoogleSignIn] ========== SUCCESS ==========")
                    print("🔵 [GoogleSignIn] Firebase UID: \(authResult.user.uid)")
                    
                    // Create/update driver document
                    let userData: [String: Any] = [
                        "id": authResult.user.uid,
                        "name": user.profile?.name ?? "Conductor",
                        "email": user.profile?.email ?? "",
                        "role": "driver",
                        "isOnline": false,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    
                    try await self?.db.collection("users").document(authResult.user.uid).setData(userData, merge: true)
                    print("🔵 [GoogleSignIn] ✓ Firestore document saved")
                    self?.isLoading = false
                } catch {
                    print("❌ [GoogleSignIn] Firebase error: \(error.localizedDescription)")
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }
        }
        print("🔵 [GoogleSignIn] ========== END INIT ==========")
    }
    
    /// Helper to get client ID from GoogleService-Info.plist
    private func getGoogleClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String else {
            return nil
        }
        return clientID
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
