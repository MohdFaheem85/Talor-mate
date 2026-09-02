import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState {
  final AuthRepository repository;

  ObserveAuthState(this.repository);

  Stream<UserEntity?> call() {
    return repository.authStateChanges;
  }
}
