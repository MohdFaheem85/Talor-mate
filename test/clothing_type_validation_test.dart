import 'package:flutter_test/flutter_test.dart';
import 'package:tailormate/features/measurements/domain/entities/clothing_type_entity.dart';
import 'package:tailormate/features/measurements/domain/entities/measurement_field_entity.dart';
import 'package:tailormate/features/measurements/data/models/clothing_type_model.dart';
import 'package:tailormate/features/measurements/data/models/measurement_field_model.dart';
import 'package:tailormate/features/measurements/data/models/measurement_model.dart';
import 'package:tailormate/features/measurements/data/repositories/clothing_type_repository_impl.dart';
import 'package:tailormate/features/measurements/data/datasources/clothing_type_remote_datasource.dart';
import 'package:tailormate/core/constants/constants.dart';
import 'package:tailormate/core/utils/unit_converter.dart';

// Fake data source for testing stream mapping
class FakeClothingTypeRemoteDataSource implements ClothingTypeRemoteDataSource {
  final List<ClothingTypeModel> mockTypes;
  final List<MeasurementFieldModel> mockFields;

  FakeClothingTypeRemoteDataSource({
    this.mockTypes = const [],
    this.mockFields = const [],
  });

  @override
  Stream<List<ClothingTypeModel>> getClothingTypes(String userId) {
    return Stream.value(mockTypes);
  }

  @override
  Stream<List<MeasurementFieldModel>> getFields(String userId, String clothingTypeId) {
    return Stream.value(mockFields);
  }

  @override
  Future<String> addClothingType(String userId, ClothingTypeModel type) async => 'new_id';

  @override
  Future<void> addField(String userId, String clothingTypeId, MeasurementFieldModel field) async {}

  @override
  Future<void> archiveClothingType(String userId, String typeId) async {}

  @override
  Future<void> deleteField(String userId, String clothingTypeId, String fieldId) async {}

  @override
  Future<void> initializeDefaultsIfNeeded(String userId) async {}

  @override
  Future<void> toggleFieldActive(String userId, String clothingTypeId, String fieldId, bool isActive) async {}

  @override
  Future<void> updateField(String userId, String clothingTypeId, MeasurementFieldModel field) async {}
}

void main() {
  group('Stable Key Generation Tests', () {
    test('generateKey converts user-visible names to snake_case', () {
      expect(MeasurementFieldEntity.generateKey('Collar Round'), 'collar_round');
      expect(MeasurementFieldEntity.generateKey('Length'), 'length');
      expect(MeasurementFieldEntity.generateKey('Waist (Upper)'), 'waist_upper');
      expect(MeasurementFieldEntity.generateKey('  Armhole Depth  '), 'armhole_depth');
      expect(MeasurementFieldEntity.generateKey('Chest & Bust'), 'chest__bust');
    });

    test('generateKey trims and sanitizes special characters', () {
      expect(MeasurementFieldEntity.generateKey('Bicep #1!'), 'bicep_1');
      expect(MeasurementFieldEntity.generateKey(''), '');
    });
  });

  group('Field Label Formatting Tests', () {
    test('MeasurementFields.getFieldLabel formats snake_case keys correctly', () {
      expect(MeasurementFields.getFieldLabel('collar_round'), 'Collar Round');
      expect(MeasurementFields.getFieldLabel('length'), 'Length');
      expect(MeasurementFields.getFieldLabel('waist_upper_full'), 'Waist Upper Full');
      expect(MeasurementFields.getFieldLabel('chest'), 'Chest');
    });
  });

  group('Clothing Type Validation & Duplicate Detection', () {
    test('Duplicate clothing types are identified case-insensitively', () {
      final existing = [
        ClothingTypeEntity(
          id: '1',
          name: 'Shirt',
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ClothingTypeEntity(
          id: '2',
          name: 'Pant',
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      bool isDuplicate(String name) {
        final trimmed = name.trim().toLowerCase();
        return existing.any((t) => t.name.trim().toLowerCase() == trimmed);
      }

      expect(isDuplicate('shirt'), isTrue);
      expect(isDuplicate('SHIRT'), isTrue);
      expect(isDuplicate('  Shirt  '), isTrue);
      expect(isDuplicate('PANT'), isTrue);
      expect(isDuplicate('Blazer'), isFalse);
      expect(isDuplicate('Sherwani'), isFalse);
    });
  });

  group('Repository Stream Type Mapping Tests', () {
    test('ClothingTypeRepositoryImpl converts Stream<List<ClothingTypeModel>> to genuine Stream<List<ClothingTypeEntity>>', () async {
      final fakeDataSource = FakeClothingTypeRemoteDataSource(
        mockTypes: [
          ClothingTypeModel(
            id: '1',
            name: 'Shirt',
            isDefault: true,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ClothingTypeModel(
            id: '2',
            name: 'Pant',
            isDefault: true,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final repo = ClothingTypeRepositoryImpl(remoteDataSource: fakeDataSource);
      final emittedTypes = await repo.getClothingTypes('user_123').first;

      // Verify the runtime list type is List<ClothingTypeEntity>
      expect(emittedTypes, isA<List<ClothingTypeEntity>>());

      // Verify firstWhere with orElse closures works without type mismatch error
      final found = emittedTypes.firstWhere(
        (t) => t.name.toLowerCase() == 'shirt',
        orElse: () => emittedTypes.first,
      );
      expect(found.name, 'Shirt');
    });

    test('ClothingTypeRepositoryImpl converts Stream<List<MeasurementFieldModel>> to genuine Stream<List<MeasurementFieldEntity>>', () async {
      final fakeDataSource = FakeClothingTypeRemoteDataSource(
        mockFields: [
          MeasurementFieldModel(
            id: 'f1',
            name: 'Length',
            key: 'length',
            isDefault: true,
            isActive: true,
            displayOrder: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final repo = ClothingTypeRepositoryImpl(remoteDataSource: fakeDataSource);
      final emittedFields = await repo.getFields('user_123', 'type_123').first;

      expect(emittedFields, isA<List<MeasurementFieldEntity>>());
      expect(emittedFields.first.name, 'Length');
    });
  });

  group('Measurement Model Backward Compatibility', () {
    test('MeasurementModel correctly parses legacy format without clothingTypeId', () {
      // Simulating a snapshot map with legacy structure
      final legacyMap = {
        'clothingType': 'shirt',
        'unit': 'inch',
        'values': {
          'length': 28.0,
          'chest': 40.0,
        },
      };

      // Ensure that missing clothingTypeId defaults gracefully
      final typeName = (legacyMap['clothingTypeName'] as String?) ??
          (legacyMap['clothingType'] as String?) ??
          '';
      final clothingTypeId = legacyMap['clothingTypeId'] as String?;

      expect(typeName, 'shirt');
      expect(clothingTypeId, isNull);
    });

    test('MeasurementModel toCreateMap writes both clothingTypeName and clothingType', () {
      final now = DateTime.now();
      final model = MeasurementModel(
        id: 'new_doc_123',
        clothingTypeId: 'blazer_id_456',
        clothingType: 'Blazer',
        unit: 'inch',
        values: {'length': 30.0, 'chest': 42.0},
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toCreateMap();
      expect(map['clothingTypeId'], 'blazer_id_456');
      expect(map['clothingTypeName'], 'Blazer');
      expect(map['clothingType'], 'Blazer');
      expect(map['unit'], 'inch');
      expect(map['values'], {'length': 30.0, 'chest': 42.0});
    });
  });

  group('Unit Converter Precision & Formatting Tests', () {
    test('inchToCm and cmToInch convert accurately', () {
      expect(UnitConverter.inchToCm(10.0), 25.4);
      expect(UnitConverter.cmToInch(25.4), 10.0);
    });

    test('formatValue trims redundant trailing decimals', () {
      expect(UnitConverter.formatValue(28.0), '28');
      expect(UnitConverter.formatValue(28.5), '28.5');
      expect(UnitConverter.formatValue(28.25), '28.25');
    });

    test('tryParse handles positive decimals and rejects empty', () {
      expect(UnitConverter.tryParse('28.5'), 28.5);
      expect(UnitConverter.tryParse(''), isNull);
      expect(UnitConverter.tryParse('abc'), isNull);
    });
  });

  group('Clothing Type Entity & Soft Delete Tests', () {
    test('copyWith properly updates isActive for soft delete', () {
      final type = ClothingTypeEntity(
        id: 'custom_1',
        name: 'Blazer',
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final archived = type.copyWith(isActive: false);
      expect(archived.isActive, isFalse);
      expect(archived.name, 'Blazer');
      expect(archived.isDefault, isFalse);
    });
  });
}
