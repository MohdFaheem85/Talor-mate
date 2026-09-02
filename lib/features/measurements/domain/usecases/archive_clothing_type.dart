import '../repositories/clothing_type_repository.dart';

class ArchiveClothingType {
  final ClothingTypeRepository repository;
  ArchiveClothingType(this.repository);

  Future<void> call(String userId, String typeId) {
    return repository.archiveClothingType(userId, typeId);
  }
}
