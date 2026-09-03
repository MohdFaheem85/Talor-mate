import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetUserProfile {
  final AuthRepository repository;

  GetUserProfile(this.repository);

  Future<UserEntity?> call(String uid) async {
    return await repository.getUserProfile(uid);
  }
}
