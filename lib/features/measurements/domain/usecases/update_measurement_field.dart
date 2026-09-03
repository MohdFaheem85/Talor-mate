import '../entities/measurement_field_entity.dart';
import '../repositories/clothing_type_repository.dart';

class UpdateMeasurementField {
  final ClothingTypeRepository repository;
  UpdateMeasurementField(this.repository);

  Future<void> call(String userId, String clothingTypeId, MeasurementFieldEntity field) {
    return repository.updateField(userId, clothingTypeId, field);
  }
}
