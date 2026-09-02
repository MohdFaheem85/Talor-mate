import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/measurement_controller.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/utils/unit_converter.dart';

class MeasurementDetailPage extends StatelessWidget {
  const MeasurementDetailPage({super.key});

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final String customerId = args['customerId'] as String;
    final MeasurementEntity measurement = args['measurement'] as MeasurementEntity;

    final controller = Get.find<MeasurementController>();
    
    // We can use a local reactive unit state to allow the viewer to temporarily convert units on screen!
    final RxString displayUnit = measurement.unit.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text('${measurement.clothingType.toUpperCase()} Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.offNamed(
                AppRoutes.addMeasurement,
                arguments: {'customerId': customerId, 'measurement': measurement},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(context, controller, customerId, measurement.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Details Summary
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recorded Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(_formatDate(measurement.createdAt)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Clothing Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(measurement.clothingType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Original Unit:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(measurement.unit.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // View Unit Switcher (allows on-the-fly conversion)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Values Displayed In:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Obx(() {
                    return SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'inch', label: Text('Inches')),
                        ButtonSegment(value: 'cm', label: Text('CM')),
                      ],
                      selected: {displayUnit.value},
                      onSelectionChanged: (set) {
                        displayUnit.value = set.first;
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 16),

              // Display values grid based on keys stored in measurement values
              Obx(() {
                final targetUnit = displayUnit.value;
                final values = measurement.values;
                final fieldKeys = values.keys.toList();

                if (fieldKeys.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No measurement values recorded in this entry.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fieldKeys.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final fieldKey = fieldKeys[index];
                    final originalValue = values[fieldKey];

                    String displayValueStr = '-';
                    if (originalValue != null) {
                      double valueToDisplay = originalValue;
                      if (measurement.unit != targetUnit) {
                        // Needs conversion
                        valueToDisplay = (targetUnit == 'cm')
                            ? UnitConverter.inchToCm(originalValue)
                            : UnitConverter.cmToInch(originalValue);
                      }
                      displayValueStr = '${UnitConverter.formatValue(valueToDisplay)} $targetUnit';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            MeasurementFields.getFieldLabel(fieldKey),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            displayValueStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: originalValue != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MeasurementController ctrl,
    String customerId,
    String measurementId,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('Are you sure you want to delete this historical measurement record permanently?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => ctrl.deleteMeasurementRecord(customerId, measurementId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
