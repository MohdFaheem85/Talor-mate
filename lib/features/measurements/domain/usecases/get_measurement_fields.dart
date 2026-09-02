import '../entities/measurement_field_entity.dart';
import '../repositories/clothing_type_repository.dart';

class GetMeasurementFields {
  final ClothingTypeRepository repository;
  GetMeasurementFields(this.repository);

  Stream<List<MeasurementFieldEntity>> call(String userId, String clothingTypeId) {
    return repository.getFields(userId, clothingTypeId);
  }
}
