import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/entities/clothing_type_entity.dart';
import '../../domain/entities/measurement_field_entity.dart';
import '../../domain/usecases/get_clothing_types.dart';
import '../../domain/usecases/add_clothing_type.dart';
import '../../domain/usecases/archive_clothing_type.dart';
import '../../domain/usecases/initialize_defaults.dart';
import '../../domain/usecases/get_measurement_fields.dart';
import '../../domain/usecases/add_measurement_field.dart';
import '../../domain/usecases/update_measurement_field.dart';
import '../../domain/usecases/delete_measurement_field.dart';
import '../../domain/usecases/toggle_field_active.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import '../../../../core/constants/constants.dart';

class ClothingTypeController extends GetxController {
  final GetClothingTypes getClothingTypesUseCase;
  final AddClothingType addClothingTypeUseCase;
  final ArchiveClothingType archiveClothingTypeUseCase;
  final InitializeDefaults initializeDefaultsUseCase;
  final GetMeasurementFields getMeasurementFieldsUseCase;
  final AddMeasurementField addMeasurementFieldUseCase;
  final UpdateMeasurementField updateMeasurementFieldUseCase;
  final DeleteMeasurementField deleteMeasurementFieldUseCase;
  final ToggleFieldActive toggleFieldActiveUseCase;

  ClothingTypeController({
    required this.getClothingTypesUseCase,
    required this.addClothingTypeUseCase,
    required this.archiveClothingTypeUseCase,
    required this.initializeDefaultsUseCase,
    required this.getMeasurementFieldsUseCase,
    required this.addMeasurementFieldUseCase,
    required this.updateMeasurementFieldUseCase,
    required this.deleteMeasurementFieldUseCase,
    required this.toggleFieldActiveUseCase,
  });

  static List<ClothingTypeEntity> get canonicalDefaultTypes => [
    ClothingTypeEntity(
      id: 'default_shirt',
      name: 'Shirt',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    ClothingTypeEntity(
      id: 'default_pant',
      name: 'Pant',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    ClothingTypeEntity(
      id: 'default_kurta',
      name: 'Kurta',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

  String? _userId;
  StreamSubscription<List<ClothingTypeEntity>>? _typesSubscription;
  StreamSubscription<List<MeasurementFieldEntity>>? _formFieldsSubscription;
  StreamSubscription<List<MeasurementFieldEntity>>? _settingsFieldsSubscription;

  final RxList<ClothingTypeEntity> clothingTypes = <ClothingTypeEntity>[
    ...canonicalDefaultTypes,
  ].obs;
  final Rxn<ClothingTypeEntity> selectedClothingType = Rxn<ClothingTypeEntity>();
  final RxBool isLoadingTypes = false.obs;

  final RxList<MeasurementFieldEntity> currentFields = <MeasurementFieldEntity>[].obs;
  final RxBool isFieldsLoading = false.obs;

  final RxList<MeasurementFieldEntity> settingsFields = <MeasurementFieldEntity>[].obs;
  final RxBool isSettingsFieldsLoading = false.obs;

  List<MeasurementFieldEntity> get activeFields {
    final list = currentFields.where((f) => f.isActive).toList();
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  List<MeasurementFieldEntity> get allSettingsFieldsSorted {
    final list = List<MeasurementFieldEntity>.from(settingsFields);
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    ever(authController.rxUser, (user) {
      if (user != null && user.isActive) {
        _initForUser(user.uid);
      } else {
        clearData();
      }
    });
    final currentUser = authController.rxUser.value;
    if (currentUser != null && currentUser.isActive) {
      _initForUser(currentUser.uid);
    }
  }

  void _initForUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;

    if (clothingTypes.isEmpty) {
      clothingTypes.assignAll(canonicalDefaultTypes);
    }
    if (selectedClothingType.value == null && clothingTypes.isNotEmpty) {
      final defaultType = clothingTypes.firstWhereOrNull(
        (t) => t.name.toLowerCase() == 'shirt',
      ) ?? clothingTypes.first;
      selectClothingType(defaultType);
    }

    isLoadingTypes.value = true;
    _typesSubscription?.cancel();
    _typesSubscription = getClothingTypesUseCase(userId).listen(
      (types) {
        if (types.isNotEmpty) {
          clothingTypes.assignAll(types);
        } else {
          clothingTypes.assignAll(canonicalDefaultTypes);
        }
        isLoadingTypes.value = false;

        final current = selectedClothingType.value;
        if (current == null || current.id.startsWith('default_')) {
          final targetName = current?.name.toLowerCase() ?? 'shirt';
          final matching = clothingTypes.firstWhereOrNull(
            (t) => t.name.toLowerCase() == targetName,
          ) ?? clothingTypes.first;
          selectClothingType(matching);
        }
      },
      onError: (e) {
        isLoadingTypes.value = false;
        debugPrint('ClothingTypeController: types stream error: $e');
      },
    );

    initializeDefaultsUseCase(userId).catchError((e) {
      debugPrint('ClothingTypeController: initializeDefaults error: $e');
    });
  }

  void clearData() {
    _typesSubscription?.cancel();
    _formFieldsSubscription?.cancel();
    _settingsFieldsSubscription?.cancel();
    _typesSubscription = null;
    _formFieldsSubscription = null;
    _settingsFieldsSubscription = null;
    clothingTypes.assignAll(canonicalDefaultTypes);
    currentFields.clear();
    settingsFields.clear();
    selectedClothingType.value = null;
    _userId = null;
  }

  void selectClothingType(ClothingTypeEntity type) {
    final userId = _userId;
    if (selectedClothingType.value?.id == type.id && currentFields.isNotEmpty) return;

    selectedClothingType.value = type;

    // Provide instant canonical fallback fields so fields appear immediately offline
    final defaultKeys = MeasurementFields.getFieldsForType(type.name);
    if (defaultKeys.isNotEmpty) {
      final fallbackEntities = defaultKeys.asMap().entries.map((e) {
        return MeasurementFieldEntity(
          id: 'default_${type.name.toLowerCase()}_${e.value}',
          name: MeasurementFields.getFieldLabel(e.value),
          key: e.value,
          isDefault: true,
          isActive: true,
          displayOrder: e.key,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
      currentFields.assignAll(fallbackEntities);
      isFieldsLoading.value = false;
    } else {
      currentFields.clear();
      isFieldsLoading.value = true;
    }

    if (userId == null) return;
    if (type.id.startsWith('default_')) return;

    _formFieldsSubscription?.cancel();
    _formFieldsSubscription = getMeasurementFieldsUseCase(userId, type.id).listen(
      (fields) {
        if (fields.isNotEmpty) {
          currentFields.value = fields;
        } else if (defaultKeys.isEmpty) {
          currentFields.value = [];
        }
        isFieldsLoading.value = false;
      },
      onError: (e) {
        isFieldsLoading.value = false;
        debugPrint('ClothingTypeController: fields stream error: $e');
      },
    );
  }

  void loadSettingsFields(String clothingTypeId) {
    final userId = _userId;
    if (userId == null) return;

    final type = clothingTypes.firstWhereOrNull((t) => t.id == clothingTypeId);
    final defaultKeys = type != null ? MeasurementFields.getFieldsForType(type.name) : <String>[];
    if (defaultKeys.isNotEmpty) {
      final fallbackEntities = defaultKeys.asMap().entries.map((e) {
        return MeasurementFieldEntity(
          id: 'default_${type!.name.toLowerCase()}_${e.value}',
          name: MeasurementFields.getFieldLabel(e.value),
          key: e.value,
          isDefault: true,
          isActive: true,
          displayOrder: e.key,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
      settingsFields.assignAll(fallbackEntities);
      isSettingsFieldsLoading.value = false;
    } else {
      settingsFields.clear();
      isSettingsFieldsLoading.value = true;
    }

    _settingsFieldsSubscription?.cancel();
    _settingsFieldsSubscription =
        getMeasurementFieldsUseCase(userId, clothingTypeId).listen(
      (fields) {
        if (fields.isNotEmpty) {
          settingsFields.value = fields;
        } else if (defaultKeys.isEmpty) {
          settingsFields.value = [];
        }
        isSettingsFieldsLoading.value = false;
      },
      onError: (e) {
        isSettingsFieldsLoading.value = false;
        debugPrint('ClothingTypeController: settings fields error: $e');
      },
    );
  }

  Future<void> addClothingType(String name) async {
    final userId = _userId;
    if (userId == null) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      Get.snackbar('Validation', 'Clothing type name cannot be empty.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final isDuplicate = clothingTypes.any(
        (t) => t.name.trim().toLowerCase() == trimmed.toLowerCase());
    if (isDuplicate) {
      Get.snackbar('Duplicate', '"$trimmed" already exists.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoadingTypes.value = true;
      final entity = ClothingTypeEntity(
        id: '',
        name: trimmed,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final newId = await addClothingTypeUseCase(userId, entity);
      // Auto select the newly added type
      final newType = entity.copyWith(id: newId);
      selectClothingType(newType);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add clothing type.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingTypes.value = false;
    }
  }

  Future<void> archiveClothingType(String typeId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      isLoadingTypes.value = true;
      await archiveClothingTypeUseCase(userId, typeId);

      if (selectedClothingType.value?.id == typeId) {
        final remaining = clothingTypes
            .where((t) => t.id != typeId && t.isActive)
            .toList();
        if (remaining.isNotEmpty) {
          selectedClothingType.value = null;
          selectClothingType(remaining.first);
        } else {
          selectedClothingType.value = null;
          currentFields.clear();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to archive clothing type.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingTypes.value = false;
    }
  }

  Future<void> addField(String clothingTypeId, String name) async {
    final userId = _userId;
    if (userId == null) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      Get.snackbar('Validation', 'Field name cannot be empty.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final key = MeasurementFieldEntity.generateKey(trimmed);
    if (key.isEmpty) {
      Get.snackbar('Validation', 'Invalid field name. Use letters and spaces.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final allCurrent = settingsFields.isEmpty ? currentFields : settingsFields;
    final isDuplicate = allCurrent.any((f) => f.key == key);
    if (isDuplicate) {
      Get.snackbar('Duplicate', 'A field similar to "$trimmed" already exists.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSettingsFieldsLoading.value = true;
      final allFields = settingsFields.isEmpty ? currentFields : settingsFields;
      final nextOrder = allFields.isEmpty
          ? 0
          : allFields.map((f) => f.displayOrder).reduce((a, b) => a > b ? a : b) + 1;

      final entity = MeasurementFieldEntity(
        id: '',
        name: trimmed,
        key: key,
        isDefault: false,
        isActive: true,
        displayOrder: nextOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await addMeasurementFieldUseCase(userId, clothingTypeId, entity);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add measurement field.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSettingsFieldsLoading.value = false;
    }
  }

  Future<void> updateFieldName(
      String clothingTypeId, MeasurementFieldEntity field, String newName) async {
    final userId = _userId;
    if (userId == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      Get.snackbar('Validation', 'Field name cannot be empty.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSettingsFieldsLoading.value = true;
      final updated = field.copyWith(name: trimmed, updatedAt: DateTime.now());
      await updateMeasurementFieldUseCase(userId, clothingTypeId, updated);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update field name.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSettingsFieldsLoading.value = false;
    }
  }

  Future<void> deleteField(String clothingTypeId, String fieldId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      isSettingsFieldsLoading.value = true;
      await deleteMeasurementFieldUseCase(userId, clothingTypeId, fieldId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete field.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSettingsFieldsLoading.value = false;
    }
  }

  Future<void> toggleFieldActive(
      String clothingTypeId, String fieldId, bool isActive) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await toggleFieldActiveUseCase(userId, clothingTypeId, fieldId, isActive);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update field.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  ClothingTypeEntity? findTypeById(String id) {
    for (final t in clothingTypes) {
      if (t.id == id) return t;
    }
    return null;
  }

  ClothingTypeEntity? findTypeByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final t in clothingTypes) {
      if (t.name.trim().toLowerCase() == lower) return t;
    }
    return null;
  }

  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}
