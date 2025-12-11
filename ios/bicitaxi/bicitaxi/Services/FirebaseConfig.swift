//
//  FirebaseConfig.swift
//  bicitaxi
//
//  Firebase configuration and initialization
//  STUB - Implement when Firebase SDK is added
//

import Foundation

/// Firebase configuration for Bici Taxi client app
/// 
/// ## Setup Instructions
/// 
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add iOS app with bundle ID: dev.zarabanda.bicitaxi.ios
/// 3. Download GoogleService-Info.plist and add to project
/// 4. Add Firebase SDK via Swift Package Manager:
///    - https://github.com/firebase/firebase-ios-sdk
///    - Select: FirebaseAuth, FirebaseFirestore, FirebaseMessaging
/// 5. Uncomment the initialization code below
/// 6. Call `FirebaseConfig.configure()` in your App's init
///
enum FirebaseConfig {
    
    // MARK: - Configuration
    
    /// Whether Firebase is enabled
    /// Set to true when Firebase SDK is integrated
    static let isEnabled = false
    
    /// Firestore collection names
    enum Collections {
        static let users = "users"
        static let rides = "rides"
        static let drivers = "drivers"
        static let payments = "payments"
    }
    
    /// Firestore document field names
    enum Fields {
        static let id = "id"
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
        static let status = "status"
        static let clientId = "client_id"
        static let driverId = "driver_id"
    }
    
    // MARK: - Initialization
    
    /// Configure Firebase SDK
    /// Call this in your App's initializer
    static func configure() {
        guard isEnabled else {
            print("⚠️ Firebase is not enabled. Using mock data.")
            return
        }
        
        // TODO: Uncomment when Firebase SDK is added
        //
        // FirebaseApp.configure()
        //
        // // Enable Firestore offline persistence
        // let settings = FirestoreSettings()
        // settings.cacheSettings = PersistentCacheSettings()
        // Firestore.firestore().settings = settings
        //
        // print("✅ Firebase configured successfully")
    }
    
    // MARK: - Auth Configuration
    
    /// Configure Firebase Authentication
    static func configureAuth() {
        guard isEnabled else { return }
        
        // TODO: Uncomment when Firebase SDK is added
        //
        // // Configure Apple Sign-In
        // // Ensure "Sign in with Apple" is enabled in Firebase Console
        //
        // // Configure Google Sign-In
        // guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        // let config = GIDConfiguration(clientID: clientID)
        // GIDSignIn.sharedInstance.configuration = config
    }
    
    // MARK: - Messaging Configuration
    
    /// Configure Firebase Cloud Messaging for push notifications
    static func configureMessaging() {
        guard isEnabled else { return }
        
        // TODO: Uncomment when Firebase SDK is added
        //
        // Messaging.messaging().delegate = <your delegate>
        //
        // // Request notification permissions
        // UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        //     print("Notification permission granted: \(granted)")
        // }
        //
        // UIApplication.shared.registerForRemoteNotifications()
    }
}

// MARK: - Firebase Error Conversion

extension FirebaseConfig {
    
    /// Convert Firebase error to AppError
    /// 
    /// - Parameter error: Firebase error
    /// - Returns: Converted AppError
    static func convertError(_ error: Error) -> AppError {
        // TODO: Uncomment when Firebase SDK is added
        //
        // if let authError = error as? AuthErrorCode {
        //     switch authError.code {
        //     case .invalidEmail:
        //         return .invalidEmail
        //     case .wrongPassword:
        //         return .invalidCredentials
        //     case .userNotFound:
        //         return .userNotFound
        //     case .emailAlreadyInUse:
        //         return .emailAlreadyInUse
        //     case .weakPassword:
        //         return .weakPassword
        //     case .networkError:
        //         return .networkUnavailable
        //     default:
        //         return .authenticationFailed(error.localizedDescription)
        //     }
        // }
        //
        // if let firestoreError = error as? FirestoreErrorCode {
        //     switch firestoreError.code {
        //     case .unavailable:
        //         return .networkUnavailable
        //     case .notFound:
        //         return .rideNotFound
        //     default:
        //         return .unknown(error.localizedDescription)
        //     }
        // }
        
        return .unknown(error.localizedDescription)
    }
}
