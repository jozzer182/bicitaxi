import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../rides/models/user_basic.dart';
import 'authentication_repository.dart';

/// Firebase implementation of [AuthenticationRepository].
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  FirebaseAuthenticationRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Stream<firebase_auth.User?> get user => _firebaseAuth.authStateChanges();

  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<firebase_auth.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // Allow UI to handle specific error codes if needed
      rethrow;
    }
  }

  @override
  Future<firebase_auth.User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);

        // Create user document in Firestore
        // Using 'users' collection to store profile data
        final userBasic = UserBasic(
          id: user.uid,
          name: name,
          phone: '', // Phone optional/not collected yet
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userBasic.toFirestore());
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Optimistically delete from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  @override
  Future<firebase_auth.User?> signInWithGoogle() async {
    print('🔐 [GoogleSignIn] Starting Google Sign-In...');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      print('🔐 [GoogleSignIn] GoogleSignIn instance created');

      print('🔐 [GoogleSignIn] Calling googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('🔐 [GoogleSignIn] User cancelled sign-in');
        return null;
      }
      print('🔐 [GoogleSignIn] User signed in: ${googleUser.email}');

      print('🔐 [GoogleSignIn] Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print(
        '🔐 [GoogleSignIn] Got tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}',
      );

      print('🔐 [GoogleSignIn] Creating Firebase credential...');
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
      print('🔐 [GoogleSignIn] Firebase credential created');

      print('🔐 [GoogleSignIn] Signing in with Firebase...');
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      print('🔐 [GoogleSignIn] Firebase sign-in complete. User: ${user?.uid}');

      if (user != null) {
        print('🔐 [GoogleSignIn] Checking if user doc exists in Firestore...');
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          print('🔐 [GoogleSignIn] Creating new user document...');
          final userBasic = UserBasic(
            id: user.uid,
            name: user.displayName ?? 'Usuario',
            phone: '',
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userBasic.toFirestore());
          print('🔐 [GoogleSignIn] User document created');
        } else {
          print('🔐 [GoogleSignIn] User document already exists');
        }
      }

      print('🔐 [GoogleSignIn] ✅ Sign-in successful!');
      return user;
    } catch (e, stackTrace) {
      print('🔐 [GoogleSignIn] ❌ ERROR: $e');
      print('🔐 [GoogleSignIn] ❌ Type: ${e.runtimeType}');
      print('🔐 [GoogleSignIn] ❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<firebase_auth.User?> signInWithApple() async {
    // Basic Apple Sign In implementation
    throw UnimplementedError('Apple Sign In not fully wired yet');
  }

  @override
  Future<firebase_auth.User?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({required String name}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      // Update Firestore user document
      await _firestore.collection('users').doc(user.uid).update({'name': name});
    } else {
      throw Exception('No user signed in');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user signed in');
    }
  }
}
