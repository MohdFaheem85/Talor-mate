import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/measurement_controller.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/custom_button.dart';

class AddEditMeasurementPage extends StatelessWidget {
  const AddEditMeasurementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final String customerId = args['customerId'] as String;
    final MeasurementEntity? measurement = args['measurement'] as MeasurementEntity?;

    final controller = Get.find<MeasurementController>();
    controller.initForm(measurement);

    final isEdit = measurement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Measurement' : 'Add Measurement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clothing Type Selection (Locked if editing)
                const Text(
                  'Clothing Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  return Row(
                    children: [
                      _buildClothingTypeRadio(context, 'shirt', 'Shirt', isEdit),
                      const SizedBox(width: 12),
                      _buildClothingTypeRadio(context, 'pant', 'Pant', isEdit),
                      const SizedBox(width: 12),
                      _buildClothingTypeRadio(context, 'kurta', 'Kurta', isEdit),
                    ],
                  );
                }),
                const SizedBox(height: 20),

                // Unit Selection (Inch / CM Toggle)
                const Text(
                  'Measurement Unit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final activeUnit = controller.selectedUnit.value;
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'inch', label: Text('Inches (in)')),
                      ButtonSegment(value: 'cm', label: Text('Centimeters (cm)')),
                    ],
                    selected: {activeUnit},
                    onSelectionChanged: (set) {
                      controller.toggleUnit(set.first);
                    },
                  );
                }),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Measurement Values',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Dynamic Measurement Fields Grid
                Obx(() {
                  final type = controller.selectedClothingType.value;
                  final fields = MeasurementFields.getFieldsForType(type);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: fields.length,
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      final txtController = controller.fieldControllers[field];
                      if (txtController == null) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MeasurementFields.getFieldLabel(field),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: TextFormField(
                              controller: txtController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                suffixText: controller.selectedUnit.value,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),

                const SizedBox(height: 36),
                Obx(() {
                  return CustomButton(
                    text: 'Save Measurement',
                    onPressed: () => controller.saveMeasurement(customerId, measurement),
                    isLoading: controller.isLoading.value,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClothingTypeRadio(
    BuildContext context,
    String value,
    String label,
    bool disabled,
  ) {
    final controller = Get.find<MeasurementController>();
    final active = controller.selectedClothingType.value == value;

    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => controller.setClothingType(value),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: active ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          child: Column(
            children: [
              Icon(
                value == 'shirt'
                    ? Icons.checkroom
                    : value == 'pant'
                        ? Icons.accessibility
                        : Icons.brush,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
