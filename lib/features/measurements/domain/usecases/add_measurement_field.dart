import '../entities/measurement_field_entity.dart';
import '../repositories/clothing_type_repository.dart';

class AddMeasurementField {
  final ClothingTypeRepository repository;
  AddMeasurementField(this.repository);

  Future<void> call(String userId, String clothingTypeId, MeasurementFieldEntity field) {
    return repository.addField(userId, clothingTypeId, field);
  }
}
