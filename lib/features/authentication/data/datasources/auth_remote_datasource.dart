import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  UserModel? getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getUserProfile(String uid);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  @override
  UserModel? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      debugPrint('AuthRemoteDataSource: getUserProfile error: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Explicitly initialize the plugin
      await _googleSignIn.initialize();

      // Trigger Google authentication flow
      final googleUser = await _googleSignIn.authenticate();

      // Obtain auth details synchronously
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create new credential using the idToken
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      // -------------------------------------------------------------
      // SERVER-SIDE AUTHORIZATION CHECK
      // -------------------------------------------------------------
      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await userDocRef.get();

      // Check 1: User document MUST exist in Firestore
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        await _forceSignOut();
        throw AccountUnauthorizedException(
          email: firebaseUser.email ?? '',
          uid: firebaseUser.uid,
        );
      }

      final data = docSnapshot.data()!;
      final isActive = data['isActive'] == true;

      // Check 2: Account MUST be active (isActive == true)
      if (!isActive) {
        await _forceSignOut();
        throw AccountDisabledException(
          email: firebaseUser.email ?? '',
          uid: firebaseUser.uid,
        );
      }

      // Check 3: Authorized! Touch only cosmetic profile fields
      final now = FieldValue.serverTimestamp();
      await userDocRef.update({
        'name': firebaseUser.displayName ?? data['name'] ?? '',
        'photoUrl': firebaseUser.photoURL ?? data['photoUrl'],
        'updatedAt': now,
      }).catchError((e) {
        debugPrint('AuthRemoteDataSource: Non-blocking profile touch error: $e');
      });

      return UserModel.fromMap(data, firebaseUser.uid);
    } on AccountUnauthorizedException {
      rethrow;
    } on AccountDisabledException {
      rethrow;
    } catch (e) {
      if (_firebaseAuth.currentUser != null) {
        await _forceSignOut();
      }
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> _forceSignOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> signOut() async {
    try {
      await _forceSignOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
