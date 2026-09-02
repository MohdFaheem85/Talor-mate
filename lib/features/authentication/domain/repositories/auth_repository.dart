import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
}
