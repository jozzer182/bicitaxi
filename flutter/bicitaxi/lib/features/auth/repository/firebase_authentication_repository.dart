
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import '../../rides/models/user_basic.dart';
import 'authentication_repository.dart';

/// Firebase implementation of [AuthenticationRepository].
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  FirebaseAuthenticationRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Stream<firebase_auth.User?> get user => _firebaseAuth.authStateChanges();

  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password) async {
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

        await _firestore.collection('users').doc(user.uid).set(userBasic.toFirestore());
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
    try {
      final gsi.GoogleSignIn googleSignIn = gsi.GoogleSignIn();
      final gsi.GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
         // Create user doc if not exists
         final userDoc = await _firestore.collection('users').doc(user.uid).get();
         if (!userDoc.exists) {
            final userBasic = UserBasic(
              id: user.uid,
              name: user.displayName ?? 'Usuario',
              phone: user.phoneNumber ?? '',
            );
            await _firestore.collection('users').doc(user.uid).set(userBasic.toFirestore());
         }
      }
      return user;
    } catch (e) {
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
}
