import '../repositories/clothing_type_repository.dart';

class InitializeDefaults {
  final ClothingTypeRepository repository;
  InitializeDefaults(this.repository);

  Future<void> call(String userId) {
    return repository.initializeDefaultsIfNeeded(userId);
  }
}
