import '../entities/clothing_type_entity.dart';
import '../entities/measurement_field_entity.dart';

abstract class ClothingTypeRepository {
  // -- Clothing Types ----------------------------------------------------------
  Stream<List<ClothingTypeEntity>> getClothingTypes(String userId);

  /// Returns the Firestore doc ID of the newly created type.
  Future<String> addClothingType(String userId, ClothingTypeEntity type);

  /// Soft-delete: sets isActive = false. Keeps measurement history intact.
  Future<void> archiveClothingType(String userId, String typeId);

  /// Idempotent: creates default types (Shirt/Pant/Kurta) only if none exist.
  Future<void> initializeDefaultsIfNeeded(String userId);

  // -- Measurement Fields -------------------------------------------------------
  Stream<List<MeasurementFieldEntity>> getFields(String userId, String clothingTypeId);
  Future<void> addField(String userId, String clothingTypeId, MeasurementFieldEntity field);
  Future<void> updateField(String userId, String clothingTypeId, MeasurementFieldEntity field);

  /// Hard-delete for custom fields only. Default fields must use toggleFieldActive.
  Future<void> deleteField(String userId, String clothingTypeId, String fieldId);
  Future<void> toggleFieldActive(
      String userId, String clothingTypeId, String fieldId, bool isActive);
}
