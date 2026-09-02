import '../entities/clothing_type_entity.dart';
import '../repositories/clothing_type_repository.dart';

class GetClothingTypes {
  final ClothingTypeRepository repository;
  GetClothingTypes(this.repository);

  Stream<List<ClothingTypeEntity>> call(String userId) {
    return repository.getClothingTypes(userId);
  }
}
