import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  UserModel? getCurrentUser();
  Stream<UserModel?> get authStateChanges;
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
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Explicitly initialize the plugin
      await _googleSignIn.initialize();

      // Trigger the Google authentication flow using the new authenticate method
      final googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details synchronously
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential using the idToken (accessToken is omitted for basic Firebase auth)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential.
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      final userModel = UserModel.fromFirebaseUser(firebaseUser);

      // Create/Update the user record in Firestore.
      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await userDocRef.get();

      final now = FieldValue.serverTimestamp();
      if (!docSnapshot.exists) {
        await userDocRef.set({
          'name': userModel.name,
          'email': userModel.email,
          'photoUrl': userModel.photoUrl,
          'createdAt': now,
          'updatedAt': now,
        });
      } else {
        await userDocRef.update({
          'name': userModel.name,
          'email': userModel.email,
          'photoUrl': userModel.photoUrl,
          'updatedAt': now,
        });
      }

      return userModel;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
