import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }

  @override
  UserEntity? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      return await remoteDataSource.signInWithGoogle();
    } catch (e) {
      throw Exception('Auth repository error during Google sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw Exception('Auth repository error during sign out: $e');
    }
  }
}
