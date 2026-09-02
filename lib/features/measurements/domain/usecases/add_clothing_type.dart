import '../entities/clothing_type_entity.dart';
import '../repositories/clothing_type_repository.dart';

class AddClothingType {
  final ClothingTypeRepository repository;
  AddClothingType(this.repository);

  Future<String> call(String userId, ClothingTypeEntity type) {
    return repository.addClothingType(userId, type);
  }
}
