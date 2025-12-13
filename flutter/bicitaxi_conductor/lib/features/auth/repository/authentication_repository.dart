
import 'package:firebase_auth/firebase_auth.dart';

/// Abstract repository for authentication operations.
abstract class AuthenticationRepository {
  /// Stream of the current authenticated user.
  Stream<User?> get user;

  /// Returns the current authenticated user synchronously.
  User? get currentUser;

  /// Signs in with email and password.
  Future<User?> signInWithEmailAndPassword(String email, String password);

  /// Creates a new user with email, password, and display name.
  Future<User?> createUserWithEmailAndPassword(String email, String password, String name);

  /// Signs out the current user.
  Future<void> signOut();

  /// Deletes the current user account.
  Future<void> deleteUser();

  /// Signs in with Google.
  Future<User?> signInWithGoogle();

  /// Signs in with Apple.
  Future<User?> signInWithApple();

  /// Signs in anonymously.
  Future<User?> signInAnonymously();
}
