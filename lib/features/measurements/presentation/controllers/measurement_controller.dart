import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/clothing_type_entity.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../domain/entities/measurement_field_entity.dart';
import '../../domain/usecases/get_measurements.dart';
import '../../domain/usecases/add_measurement.dart';
import '../../domain/usecases/update_measurement.dart';
import '../../domain/usecases/delete_measurement.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'clothing_type_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/unit_converter.dart';

class MeasurementController extends GetxController {
  final GetMeasurements getMeasurementsUseCase;
  final AddMeasurement addMeasurementUseCase;
  final UpdateMeasurement updateMeasurementUseCase;
  final DeleteMeasurement deleteMeasurementUseCase;

  MeasurementController({
    required this.getMeasurementsUseCase,
    required this.addMeasurementUseCase,
    required this.updateMeasurementUseCase,
    required this.deleteMeasurementUseCase,
  });

  final AuthController _authController = Get.find<AuthController>();

  final RxList<MeasurementEntity> measurementHistory = <MeasurementEntity>[].obs;
  final RxnString selectedClothingTypeId = RxnString();
  final RxString selectedClothingType = 'Shirt'.obs;
  final RxString selectedUnit = 'inch'.obs;
  final RxBool isLoading = false.obs;

  // Stream subscription for active measurement history listener
  StreamSubscription<List<MeasurementEntity>>? _historySubscription;

  // Track CREATE vs EDIT mode
  final RxBool isEditMode = false.obs;
  final Rxn<MeasurementEntity> currentEditingMeasurement = Rxn<MeasurementEntity>();

  // Map to hold text editing controllers dynamically per field
  final RxMap<String, TextEditingController> fieldControllers = <String, TextEditingController>{}.obs;
  final formKey = GlobalKey<FormState>();

  Worker? _fieldsWorker;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    
    // Automatically cancel listeners and clear state when signing out or inactive
    _authWorker = ever(_authController.rxUser, (user) {
      if (user == null || !user.isActive) {
        clearData();
      }
    });

    // Listen to changes in activeFields of ClothingTypeController if registered
    if (Get.isRegistered<ClothingTypeController>()) {
      final clothingTypeCtrl = Get.find<ClothingTypeController>();
      _fieldsWorker = ever(clothingTypeCtrl.currentFields, (List<MeasurementFieldEntity> fields) {
        final initialVals = isEditMode.value ? currentEditingMeasurement.value?.values : null;
        syncFieldsFromEntityList(
          fields,
          initialValues: initialVals,
          preserveTypedValues: true,
        );
      });
    }
  }

  void cancelHistorySubscription() {
    _historySubscription?.cancel();
    _historySubscription = null;
    measurementHistory.clear();
  }

  void clearData() {
    _historySubscription?.cancel();
    _historySubscription = null;
    measurementHistory.clear();
    resetForm();
  }

  void loadHistory(String customerId) {
    _historySubscription?.cancel();
    final userId = _authController.rxUser.value?.uid;
    if (userId != null) {
      _historySubscription = getMeasurementsUseCase(userId, customerId).listen(
        (history) {
          measurementHistory.value = history;
        },
        onError: (error) {
          debugPrint('Measurement history stream error: $error');
        },
      );
    }
  }

  /// Syncs field controllers with the given list of fields.
  /// [preserveTypedValues]: only keep user-typed text if explicitly requested (e.g. dynamic field added in-place).
  void syncFieldsFromEntityList(
    List<MeasurementFieldEntity> fields, {
    Map<String, double>? initialValues,
    bool preserveTypedValues = false,
  }) {
    final currentValues = <String, String>{};
    if (preserveTypedValues) {
      fieldControllers.forEach((key, ctrl) {
        currentValues[key] = ctrl.text;
      });
    }

    // Clear and dispose old controllers
    fieldControllers.forEach((_, controller) => controller.dispose());
    fieldControllers.clear();

    final activeList = fields.where((f) => f.isActive).toList();
    if (activeList.isNotEmpty) {
      for (var field in activeList) {
        final ctrl = TextEditingController();
        if (initialValues != null && initialValues.containsKey(field.key)) {
          ctrl.text = UnitConverter.formatValue(initialValues[field.key]!);
        } else if (preserveTypedValues && currentValues.containsKey(field.key)) {
          ctrl.text = currentValues[field.key]!;
        }
        fieldControllers[field.key] = ctrl;
      }
    } else {
      final fallbackKeys = MeasurementFields.getFieldsForType(selectedClothingType.value);
      for (var key in fallbackKeys) {
        final ctrl = TextEditingController();
        if (initialValues != null && initialValues.containsKey(key)) {
          ctrl.text = UnitConverter.formatValue(initialValues[key]!);
        } else if (preserveTypedValues && currentValues.containsKey(key)) {
          ctrl.text = currentValues[key]!;
        }
        fieldControllers[key] = ctrl;
      }
    }

    // If initialValues had any legacy/disabled keys present in historical record, add controllers for them
    if (initialValues != null) {
      initialValues.forEach((key, val) {
        if (!fieldControllers.containsKey(key)) {
          final ctrl = TextEditingController();
          ctrl.text = UnitConverter.formatValue(val);
          fieldControllers[key] = ctrl;
        }
      });
    }
  }

  void _fallbackInitializeFieldControllers(String type, [Map<String, double>? initialValues]) {
    fieldControllers.forEach((_, controller) => controller.dispose());
    fieldControllers.clear();

    final fields = MeasurementFields.getFieldsForType(type);
    for (var field in fields) {
      final ctrl = TextEditingController();
      if (initialValues != null && initialValues.containsKey(field)) {
        ctrl.text = UnitConverter.formatValue(initialValues[field]!);
      }
      fieldControllers[field] = ctrl;
    }

    if (initialValues != null) {
      initialValues.forEach((key, val) {
        if (!fieldControllers.containsKey(key)) {
          final ctrl = TextEditingController();
          ctrl.text = UnitConverter.formatValue(val);
          fieldControllers[key] = ctrl;
        }
      });
    }
  }

  void setClothingTypeEntity(ClothingTypeEntity type) {
    selectedClothingTypeId.value = type.id;
    selectedClothingType.value = type.name;

    if (Get.isRegistered<ClothingTypeController>()) {
      final clothingTypeCtrl = Get.find<ClothingTypeController>();
      clothingTypeCtrl.selectClothingType(type);

      final isEditingSameType = isEditMode.value &&
          (currentEditingMeasurement.value?.clothingTypeId == type.id ||
              currentEditingMeasurement.value?.clothingType.toLowerCase() ==
                  type.name.toLowerCase());

      final initialVals = isEditingSameType ? currentEditingMeasurement.value?.values : null;

      syncFieldsFromEntityList(
        clothingTypeCtrl.currentFields,
        initialValues: initialVals,
        preserveTypedValues: false,
      );
    } else {
      final isEditingSameType = isEditMode.value &&
          currentEditingMeasurement.value?.clothingType.toLowerCase() == type.name.toLowerCase();
      _fallbackInitializeFieldControllers(
        type.name,
        isEditingSameType ? currentEditingMeasurement.value?.values : null,
      );
    }
  }

  void toggleUnit(String newUnit) {
    if (selectedUnit.value == newUnit) return;

    // Convert values currently in form
    fieldControllers.forEach((key, controller) {
      final parsed = UnitConverter.tryParse(controller.text);
      if (parsed != null) {
        final converted = (newUnit == 'cm')
            ? UnitConverter.inchToCm(parsed)
            : UnitConverter.cmToInch(parsed);
        controller.text = UnitConverter.formatValue(converted);
      }
    });

    selectedUnit.value = newUnit;
  }

  /// Initializes the form with clean state for CREATE mode, or existing values for EDIT mode.
  void initForm(MeasurementEntity? measurement) {
    isLoading.value = false;
    if (measurement != null) {
      // ── EDIT MODE ────────────────────────────────────────────────────────
      isEditMode.value = true;
      currentEditingMeasurement.value = measurement;
      selectedClothingTypeId.value = measurement.clothingTypeId;
      selectedClothingType.value = measurement.clothingType;
      selectedUnit.value = measurement.unit;

      if (Get.isRegistered<ClothingTypeController>()) {
        final clothingTypeCtrl = Get.find<ClothingTypeController>();
        ClothingTypeEntity? found;
        if (measurement.clothingTypeId != null) {
          found = clothingTypeCtrl.findTypeById(measurement.clothingTypeId!);
        }
        found ??= clothingTypeCtrl.findTypeByName(measurement.clothingType);

        if (found != null) {
          clothingTypeCtrl.selectClothingType(found);
          syncFieldsFromEntityList(
            clothingTypeCtrl.currentFields,
            initialValues: measurement.values,
            preserveTypedValues: false,
          );
        } else {
          _fallbackInitializeFieldControllers(measurement.clothingType, measurement.values);
        }
      } else {
        _fallbackInitializeFieldControllers(measurement.clothingType, measurement.values);
      }
    } else {
      // ── CREATE MODE (Always fresh & empty) ─────────────────────────────────
      isEditMode.value = false;
      currentEditingMeasurement.value = null;
      selectedUnit.value = 'inch';

      if (Get.isRegistered<ClothingTypeController>()) {
        final clothingTypeCtrl = Get.find<ClothingTypeController>();
        
        final defaultType = clothingTypeCtrl.clothingTypes.firstWhereOrNull(
              (t) => t.name.toLowerCase() == 'shirt',
            ) ??
            clothingTypeCtrl.clothingTypes.firstOrNull ??
            clothingTypeCtrl.selectedClothingType.value ??
            ClothingTypeController.canonicalDefaultTypes.first;

        selectedClothingTypeId.value = defaultType.id;
        selectedClothingType.value = defaultType.name;
        clothingTypeCtrl.selectClothingType(defaultType);
        syncFieldsFromEntityList(
          clothingTypeCtrl.currentFields,
          initialValues: null,
          preserveTypedValues: false,
        );
      } else {
        selectedClothingTypeId.value = null;
        selectedClothingType.value = 'Shirt';
        _fallbackInitializeFieldControllers('shirt', null);
      }
    }
  }

  void resetForm() {
    isEditMode.value = false;
    currentEditingMeasurement.value = null;
    fieldControllers.forEach((_, controller) => controller.dispose());
    fieldControllers.clear();
    selectedUnit.value = 'inch';
    isLoading.value = false;
  }

  Future<void> saveMeasurement(String customerId, MeasurementEntity? existing) async {
    if (!formKey.currentState!.validate()) return;

    final userId = _authController.rxUser.value?.uid;
    if (userId == null) return;

    try {
      isLoading.value = true;
      final Map<String, double> values = {};
      bool hasOneValue = false;

      // Extract and validate fields
      for (var entry in fieldControllers.entries) {
        final val = UnitConverter.tryParse(entry.value.text);
        if (val != null) {
          if (val <= 0) {
            Get.snackbar('Error', 'Measurement values must be positive numbers.');
            isLoading.value = false;
            return;
          }
          values[entry.key] = val;
          hasOneValue = true;
        }
      }

      if (!hasOneValue) {
        Get.snackbar('Validation Alert', 'Please fill in at least one measurement field.');
        isLoading.value = false;
        return;
      }

      if (existing == null) {
        // Create new document (never overwrite history)
        final newMeasurement = MeasurementEntity(
          id: '',
          clothingTypeId: selectedClothingTypeId.value,
          clothingType: selectedClothingType.value,
          unit: selectedUnit.value,
          values: values,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await addMeasurementUseCase(userId, customerId, newMeasurement);
        resetForm();
        Get.back();
        Get.snackbar('Saved', 'New measurement added to history.');
      } else {
        // Update existing historical document
        final updatedMeasurement = existing.copyWith(
          clothingTypeId: selectedClothingTypeId.value ?? existing.clothingTypeId,
          clothingType: selectedClothingType.value,
          unit: selectedUnit.value,
          values: values,
          updatedAt: DateTime.now(),
        );
        await updateMeasurementUseCase(userId, customerId, updatedMeasurement);
        resetForm();
        Get.back();
        Get.snackbar('Saved', 'Measurement updated successfully.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save measurement data.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMeasurementRecord(String customerId, String measurementId) async {
    final userId = _authController.rxUser.value?.uid;
    if (userId == null) return;

    try {
      isLoading.value = true;
      await deleteMeasurementUseCase(userId, customerId, measurementId);
      Get.back();
      Get.snackbar('Deleted', 'Measurement history item removed.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete measurement.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _historySubscription?.cancel();
    _authWorker?.dispose();
    _fieldsWorker?.dispose();
    fieldControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }
}
