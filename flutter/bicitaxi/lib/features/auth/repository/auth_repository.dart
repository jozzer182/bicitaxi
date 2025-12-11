import '../models/app_user.dart';

/// Abstract repository for authentication operations.
/// TODO: Implement with Firebase Auth when integrating Firebase.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  /// Emits the current user when signed in, null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Gets the currently authenticated user, if any.
  Future<AppUser?> get currentUser;

  /// Signs in with email and password.
  /// Throws [AuthException] on failure.
  Future<AppUser> signInWithEmail(String email, String password);

  /// Signs in with Google account.
  /// Throws [AuthException] on failure.
  Future<AppUser> signInWithGoogle();

  /// Signs in with Apple account (iOS only).
  /// Throws [AuthException] on failure.
  Future<AppUser> signInWithApple();

  /// Signs in anonymously (guest mode).
  /// Returns an anonymous user that can be linked to a full account later.
  Future<AppUser> signInAnonymously();

  /// Registers a new user with email and password.
  /// Throws [AuthException] on failure.
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Updates the current user's profile information.
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email);

  /// Changes the current user's password.
  /// Requires re-authentication with the current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Deletes the current user's account.
  /// This is a destructive operation that cannot be undone.
  Future<void> deleteAccount();
}

/// Exception thrown by auth operations.
class AuthException implements Exception {
  const AuthException({required this.code, required this.message});

  /// Error code (e.g., 'email-already-in-use', 'wrong-password')
  final String code;

  /// Human-readable error message
  final String message;

  @override
  String toString() => 'AuthException($code): $message';

  /// Common error codes
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String invalidEmail = 'invalid-email';
  static const String userNotFound = 'user-not-found';
  static const String wrongPassword = 'wrong-password';
  static const String weakPassword = 'weak-password';
  static const String networkError = 'network-error';
  static const String userDisabled = 'user-disabled';
  static const String operationNotAllowed = 'operation-not-allowed';
  static const String tooManyRequests = 'too-many-requests';
}
