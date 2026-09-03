import 'package:flutter_test/flutter_test.dart';
import 'package:tailormate/features/measurements/domain/entities/measurement_entity.dart';
import 'package:tailormate/features/measurements/domain/entities/measurement_field_entity.dart';
import 'package:tailormate/features/measurements/domain/entities/clothing_type_entity.dart';
import 'package:tailormate/features/measurements/presentation/controllers/measurement_controller.dart';
import 'package:tailormate/features/measurements/domain/usecases/get_measurements.dart';
import 'package:tailormate/features/measurements/domain/usecases/add_measurement.dart';
import 'package:tailormate/features/measurements/domain/usecases/update_measurement.dart';
import 'package:tailormate/features/measurements/domain/usecases/delete_measurement.dart';
import 'package:tailormate/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:get/get.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_in_with_google.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_out.dart';
import 'package:tailormate/features/authentication/domain/usecases/observe_auth_state.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_user_profile.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_current_user.dart';
import 'package:tailormate/features/authentication/domain/repositories/auth_repository.dart';
import 'package:tailormate/features/authentication/domain/entities/user_entity.dart';

class MockMeasurementRepository implements MeasurementRepository {
  @override
  Future<void> addMeasurement(String userId, String customerId, MeasurementEntity measurement) async {}
  @override
  Future<void> deleteMeasurement(String userId, String customerId, String measurementId) async {}
  @override
  Stream<List<MeasurementEntity>> getMeasurements(String userId, String customerId) => Stream.value([]);
  @override
  Future<void> updateMeasurement(String userId, String customerId, MeasurementEntity measurement) async {}
}

class MockAuthRepository implements AuthRepository {
  static final _now = DateTime(2026, 1, 1);
  static final _mockUser = UserEntity(
    uid: 'test_uid',
    name: 'Test User',
    email: 'test@example.com',
    isActive: true,
    role: 'user',
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(_mockUser);
  @override
  UserEntity? getCurrentUser() => _mockUser;
  @override
  Future<UserEntity?> signInWithGoogle() async => _mockUser;
  @override
  Future<void> signOut() async {}
  @override
  Future<UserEntity?> getUserProfile(String uid) async => _mockUser;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeasurementController controller;

  setUp(() {
    Get.reset();

    final authRepo = MockAuthRepository();
    Get.put(AuthController(
      signInWithGoogleUseCase: SignInWithGoogle(authRepo),
      signOutUseCase: SignOut(authRepo),
      observeAuthStateUseCase: ObserveAuthState(authRepo),
      getUserProfileUseCase: GetUserProfile(authRepo),
      getCurrentUserUseCase: GetCurrentUser(authRepo),
    ));

    final measurementRepo = MockMeasurementRepository();
    controller = MeasurementController(
      getMeasurementsUseCase: GetMeasurements(measurementRepo),
      addMeasurementUseCase: AddMeasurement(measurementRepo),
      updateMeasurementUseCase: UpdateMeasurement(measurementRepo),
      deleteMeasurementUseCase: DeleteMeasurement(measurementRepo),
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('Measurement Form State - CREATE vs EDIT Mode Tests', () {
    test('initForm(null) in CREATE mode initializes all fields as completely empty', () {
      controller.initForm(null);

      expect(controller.isEditMode.value, isFalse);
      expect(controller.currentEditingMeasurement.value, isNull);
      expect(controller.selectedUnit.value, 'inch');

      for (var ctrl in controller.fieldControllers.values) {
        expect(ctrl.text, isEmpty);
      }
    });

    test('CREATE -> Enter values -> Save/Reset -> Next CREATE session MUST be completely empty', () {
      // 1. First CREATE session
      controller.initForm(null);

      // Simulate user typing values
      final sampleFields = [
        MeasurementFieldEntity(
          id: '1',
          name: 'Length',
          key: 'length',
          isDefault: true,
          isActive: true,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MeasurementFieldEntity(
          id: '2',
          name: 'Chest',
          key: 'chest',
          isDefault: true,
          isActive: true,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MeasurementFieldEntity(
          id: '3',
          name: 'Waist',
          key: 'waist',
          isDefault: true,
          isActive: true,
          displayOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      controller.syncFieldsFromEntityList(sampleFields, preserveTypedValues: false);

      controller.fieldControllers['length']?.text = '28';
      controller.fieldControllers['chest']?.text = '40';
      controller.fieldControllers['waist']?.text = '36';

      expect(controller.fieldControllers['chest']?.text, '40');

      // 2. Simulate Save/Reset
      controller.resetForm();

      expect(controller.fieldControllers, isEmpty);

      // 3. Second CREATE session for another measurement
      controller.initForm(null);
      controller.syncFieldsFromEntityList(sampleFields, preserveTypedValues: false);

      // EVERY FIELD MUST BE EMPTY
      expect(controller.fieldControllers['length']?.text, isEmpty);
      expect(controller.fieldControllers['chest']?.text, isEmpty);
      expect(controller.fieldControllers['waist']?.text, isEmpty);
    });

    test('initForm(existing) in EDIT mode correctly populates saved values', () {
      final existingRecord = MeasurementEntity(
        id: 'rec_123',
        clothingTypeId: 'shirt_id',
        clothingType: 'Shirt',
        unit: 'inch',
        values: {
          'length': 28.5,
          'chest': 40.0,
          'waist': 36.0,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.initForm(existingRecord);

      expect(controller.isEditMode.value, isTrue);
      expect(controller.currentEditingMeasurement.value?.id, 'rec_123');
      expect(controller.selectedClothingType.value, 'Shirt');
      expect(controller.selectedUnit.value, 'inch');

      expect(controller.fieldControllers['length']?.text, '28.5');
      expect(controller.fieldControllers['chest']?.text, '40');
      expect(controller.fieldControllers['waist']?.text, '36');
    });

    test('Switching clothing type in CREATE mode starts fresh and does not leak values', () {
      // 1. User starts in CREATE mode
      controller.initForm(null);

      final shirtFields = [
        MeasurementFieldEntity(
          id: '1',
          name: 'Length',
          key: 'length',
          isDefault: true,
          isActive: true,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MeasurementFieldEntity(
          id: '2',
          name: 'Chest',
          key: 'chest',
          isDefault: true,
          isActive: true,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      controller.syncFieldsFromEntityList(shirtFields, preserveTypedValues: false);
      controller.fieldControllers['length']?.text = '28';
      controller.fieldControllers['chest']?.text = '40';

      // 2. User switches to Pant
      final pantType = ClothingTypeEntity(
        id: 'pant_id',
        name: 'Pant',
        isDefault: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.setClothingTypeEntity(pantType);

      final pantFields = [
        MeasurementFieldEntity(
          id: '3',
          name: 'Length',
          key: 'length',
          isDefault: true,
          isActive: true,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MeasurementFieldEntity(
          id: '4',
          name: 'Waist',
          key: 'waist',
          isDefault: true,
          isActive: true,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      controller.syncFieldsFromEntityList(pantFields, preserveTypedValues: false);

      // Pant's length must NOT have inherited Shirt's '28'
      expect(controller.fieldControllers['length']?.text, isEmpty);
      expect(controller.fieldControllers['waist']?.text, isEmpty);
    });

    test('Unit toggle accurately converts numbers on the fly without erasing fields', () {
      controller.initForm(null);

      final fields = [
        MeasurementFieldEntity(
          id: '1',
          name: 'Length',
          key: 'length',
          isDefault: true,
          isActive: true,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      controller.syncFieldsFromEntityList(fields, preserveTypedValues: false);
      controller.fieldControllers['length']?.text = '10'; // 10 inches

      // Toggle to cm (10 inches * 2.54 = 25.4 cm)
      controller.toggleUnit('cm');
      expect(controller.selectedUnit.value, 'cm');
      expect(controller.fieldControllers['length']?.text, '25.4');

      // Toggle back to inch
      controller.toggleUnit('inch');
      expect(controller.selectedUnit.value, 'inch');
      expect(controller.fieldControllers['length']?.text, '10');
    });
  });
}
