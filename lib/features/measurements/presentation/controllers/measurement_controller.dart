import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../domain/usecases/get_measurements.dart';
import '../../domain/usecases/add_measurement.dart';
import '../../domain/usecases/update_measurement.dart';
import '../../domain/usecases/delete_measurement.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
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
  final RxString selectedClothingType = 'shirt'.obs;
  final RxString selectedUnit = 'inch'.obs;
  final RxBool isLoading = false.obs;

  // Map to hold text editing controllers dynamically per field
  final RxMap<String, TextEditingController> fieldControllers = <String, TextEditingController>{}.obs;
  final formKey = GlobalKey<FormState>();

  void loadHistory(String customerId) {
    final userId = _authController.rxUser.value?.uid;
    if (userId != null) {
      measurementHistory.bindStream(getMeasurementsUseCase(userId, customerId));
    }
  }

  void _initializeFieldControllers(String type) {
    // Clear old controllers
    fieldControllers.forEach((_, controller) => controller.dispose());
    fieldControllers.clear();

    final fields = MeasurementFields.getFieldsForType(type);
    for (var field in fields) {
      fieldControllers[field] = TextEditingController();
    }
  }

  void setClothingType(String type) {
    selectedClothingType.value = type;
    _initializeFieldControllers(type);
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

  void initForm(MeasurementEntity? measurement) {
    if (measurement != null) {
      selectedClothingType.value = measurement.clothingType;
      selectedUnit.value = measurement.unit;
      _initializeFieldControllers(measurement.clothingType);

      // Set values
      measurement.values.forEach((key, val) {
        if (fieldControllers.containsKey(key)) {
          fieldControllers[key]!.text = UnitConverter.formatValue(val);
        }
      });
    } else {
      // Default form state
      selectedClothingType.value = 'shirt';
      selectedUnit.value = 'inch';
      _initializeFieldControllers('shirt');
    }
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
          clothingType: selectedClothingType.value,
          unit: selectedUnit.value,
          values: values,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await addMeasurementUseCase(userId, customerId, newMeasurement);
        Get.back();
        Get.snackbar('Saved', 'New measurement added to history.');
      } else {
        // Update existing historical document
        final updatedMeasurement = existing.copyWith(
          clothingType: selectedClothingType.value,
          unit: selectedUnit.value,
          values: values,
          updatedAt: DateTime.now(),
        );
        await updateMeasurementUseCase(userId, customerId, updatedMeasurement);
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
    fieldControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }
}
