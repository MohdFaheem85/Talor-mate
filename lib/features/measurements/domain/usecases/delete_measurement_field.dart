import '../repositories/clothing_type_repository.dart';

class DeleteMeasurementField {
  final ClothingTypeRepository repository;
  DeleteMeasurementField(this.repository);

  Future<void> call(String userId, String clothingTypeId, String fieldId) {
    return repository.deleteField(userId, clothingTypeId, fieldId);
  }
}
