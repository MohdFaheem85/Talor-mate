import 'package:flutter_test/flutter_test.dart';
import 'package:tailormate/features/customers/data/models/customer_model.dart';
import 'package:tailormate/features/measurements/data/models/measurement_model.dart';
import 'package:tailormate/features/measurements/data/models/clothing_type_model.dart';
import 'package:tailormate/features/measurements/data/models/measurement_field_model.dart';
import 'package:tailormate/core/services/sync_status_service.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline-First Model Parsing & Persistence Tests', () {
    test('CustomerModel handles offline creation payloads with FieldValue timestamps', () {
      final customer = CustomerModel(
        id: 'cust_offline_1',
        name: 'John Doe',
        phone: '9876543210',
        email: 'john@example.com',
        address: 'Main St',
        notes: 'Fitting test',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final createMap = customer.toCreateMap();
      expect(createMap['name'], 'John Doe');
      expect(createMap['phone'], '9876543210');
      expect(createMap.containsKey('createdAt'), isTrue);
      expect(createMap.containsKey('updatedAt'), isTrue);

      final updateMap = customer.toUpdateMap();
      expect(updateMap['name'], 'John Doe');
      expect(updateMap.containsKey('updatedAt'), isTrue);
    });

    test('MeasurementModel toCreateMap preserves stable clothingTypeId and human-readable name', () {
      final measurement = MeasurementModel(
        id: 'meas_offline_1',
        clothingTypeId: 'shirt_type_123',
        clothingType: 'Shirt',
        unit: 'inch',
        values: {'chest': 42.0, 'length': 29.5},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final createMap = measurement.toCreateMap();
      expect(createMap['clothingTypeId'], 'shirt_type_123');
      expect(createMap['clothingTypeName'], 'Shirt');
      expect(createMap['clothingType'], 'Shirt');
      expect(createMap['unit'], 'inch');
      expect(createMap['values'], {'chest': 42.0, 'length': 29.5});
      expect(createMap.containsKey('createdAt'), isTrue);
      expect(createMap.containsKey('updatedAt'), isTrue);
    });

    test('ClothingTypeModel toCreateMap produces valid active structure', () {
      final clothingType = ClothingTypeModel(
        id: 'type_1',
        name: 'Blazer',
        isDefault: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final createMap = clothingType.toCreateMap();
      expect(createMap['name'], 'Blazer');
      expect(createMap['isDefault'], isFalse);
      expect(createMap['isActive'], isTrue);
      expect(createMap.containsKey('createdAt'), isTrue);
    });

    test('MeasurementFieldModel toCreateMap and toUpdateMap preserve stable field key', () {
      final field = MeasurementFieldModel(
        id: 'f_1',
        name: 'Lapel Width',
        key: 'lapel_width',
        isDefault: false,
        isActive: true,
        displayOrder: 4,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final createMap = field.toCreateMap();
      expect(createMap['name'], 'Lapel Width');
      expect(createMap['key'], 'lapel_width');
      expect(createMap['displayOrder'], 4);

      final updateMap = field.toUpdateMap();
      expect(updateMap['name'], 'Lapel Width');
      expect(updateMap['displayOrder'], 4);
      // Key must NOT be in update map to preserve stable references
      expect(updateMap.containsKey('key'), isFalse);
    });
  });

  group('SyncStatusService Reactive State Tests', () {
    tearDown(() {
      Get.reset();
    });

    test('SyncStatusService initializes with default non-blocking values', () {
      final service = SyncStatusService();
      expect(service.isOffline.value, isFalse);
      expect(service.isSyncing.value, isFalse);
      service.onClose();
    });

    test('SyncStatusService reacts to offline and syncing state toggles', () {
      final service = SyncStatusService();
      
      service.isOffline.value = true;
      expect(service.isOffline.value, isTrue);

      service.isSyncing.value = true;
      expect(service.isSyncing.value, isTrue);

      service.isOffline.value = false;
      service.isSyncing.value = false;
      expect(service.isOffline.value, isFalse);
      expect(service.isSyncing.value, isFalse);

      service.onClose();
    });
  });
}
