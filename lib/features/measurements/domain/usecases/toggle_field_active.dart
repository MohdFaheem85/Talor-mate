import '../repositories/clothing_type_repository.dart';

class ToggleFieldActive {
  final ClothingTypeRepository repository;
  ToggleFieldActive(this.repository);

  Future<void> call(String userId, String clothingTypeId, String fieldId, bool isActive) {
    return repository.toggleFieldActive(userId, clothingTypeId, fieldId, isActive);
  }
}
