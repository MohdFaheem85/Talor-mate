import '../../domain/entities/clothing_type_entity.dart';
import '../../domain/entities/measurement_field_entity.dart';
import '../../domain/repositories/clothing_type_repository.dart';
import '../datasources/clothing_type_remote_datasource.dart';
import '../models/clothing_type_model.dart';
import '../models/measurement_field_model.dart';

class ClothingTypeRepositoryImpl implements ClothingTypeRepository {
  final ClothingTypeRemoteDataSource remoteDataSource;

  ClothingTypeRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ClothingTypeEntity>> getClothingTypes(String userId) {
    return remoteDataSource
        .getClothingTypes(userId)
        .map((models) => models.map<ClothingTypeEntity>((m) => m).toList());
  }

  @override
  Future<String> addClothingType(String userId, ClothingTypeEntity type) {
    final model = ClothingTypeModel.fromEntity(type);
    return remoteDataSource.addClothingType(userId, model);
  }

  @override
  Future<void> archiveClothingType(String userId, String typeId) {
    return remoteDataSource.archiveClothingType(userId, typeId);
  }

  @override
  Future<void> initializeDefaultsIfNeeded(String userId) {
    return remoteDataSource.initializeDefaultsIfNeeded(userId);
  }

  @override
  Stream<List<MeasurementFieldEntity>> getFields(
      String userId, String clothingTypeId) {
    return remoteDataSource
        .getFields(userId, clothingTypeId)
        .map((models) => models.map<MeasurementFieldEntity>((m) => m).toList());
  }

  @override
  Future<void> addField(
      String userId, String clothingTypeId, MeasurementFieldEntity field) {
    final model = MeasurementFieldModel.fromEntity(field);
    return remoteDataSource.addField(userId, clothingTypeId, model);
  }

  @override
  Future<void> updateField(
      String userId, String clothingTypeId, MeasurementFieldEntity field) {
    final model = MeasurementFieldModel.fromEntity(field);
    return remoteDataSource.updateField(userId, clothingTypeId, model);
  }

  @override
  Future<void> deleteField(
      String userId, String clothingTypeId, String fieldId) {
    return remoteDataSource.deleteField(userId, clothingTypeId, fieldId);
  }

  @override
  Future<void> toggleFieldActive(
      String userId, String clothingTypeId, String fieldId, bool isActive) {
    return remoteDataSource.toggleFieldActive(
        userId, clothingTypeId, fieldId, isActive);
  }
}
