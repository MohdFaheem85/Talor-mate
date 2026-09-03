import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/measurement_controller.dart';
import '../controllers/clothing_type_controller.dart';
import '../../domain/entities/measurement_entity.dart';
import '../../domain/entities/clothing_type_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/offline_banner.dart';

class AddEditMeasurementPage extends StatelessWidget {
  const AddEditMeasurementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final String customerId = args['customerId'] as String;
    final MeasurementEntity? measurement = args['measurement'] as MeasurementEntity?;

    final controller = Get.find<MeasurementController>();
    final clothingTypeCtrl = Get.find<ClothingTypeController>();
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
                const OfflineBanner(),
                // Clothing Type Selection
                const Text(
                  'Clothing Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // Horizontal scrolling clothing type selector
                Obx(() {
                  final rawTypes = clothingTypeCtrl.clothingTypes;
                  final types = rawTypes.isNotEmpty
                      ? rawTypes
                      : ClothingTypeController.canonicalDefaultTypes;
                  final currentSelected = clothingTypeCtrl.selectedClothingType.value;

                  return SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: types.length + (isEdit ? 0 : 1),
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index < types.length) {
                          final type = types[index];
                          final isSelected = currentSelected?.id == type.id ||
                              controller.selectedClothingType.value.toLowerCase() ==
                                  type.name.toLowerCase();

                          return _buildClothingTypeChip(
                            context,
                            type: type,
                            isSelected: isSelected,
                            disabled: isEdit,
                            onTap: () {
                              controller.setClothingTypeEntity(type);
                            },
                          );
                        } else {
                          // "+" Add Clothing Type button at the end
                          return _buildAddClothingTypeButton(context, clothingTypeCtrl);
                        }
                      },
                    ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Measurement Values',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Obx(() {
                      final currentType = clothingTypeCtrl.selectedClothingType.value;
                      if (currentType != null) {
                        return TextButton.icon(
                          onPressed: () => _showQuickAddFieldDialog(
                            context,
                            clothingTypeCtrl,
                            controller,
                            currentType.id,
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Field', style: TextStyle(fontSize: 13)),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Dynamic Measurement Fields Grid
                Obx(() {
                  if (clothingTypeCtrl.isFieldsLoading.value &&
                      clothingTypeCtrl.currentFields.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Active fields from ClothingTypeController
                  final activeFields = clothingTypeCtrl.activeFields;

                  if (activeFields.isEmpty && controller.fieldControllers.isEmpty) {
                    final currentType = clothingTypeCtrl.selectedClothingType.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.straighten_outlined, size: 40, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text(
                            'No fields configured for ${currentType?.name ?? 'this garment'}.',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: currentType == null
                                ? null
                                : () => _showQuickAddFieldDialog(
                                      context,
                                      clothingTypeCtrl,
                                      controller,
                                      currentType.id,
                                    ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add First Field'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Use fieldControllers keys to render input fields
                  final fieldKeys = controller.fieldControllers.keys.toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: fieldKeys.length,
                    itemBuilder: (context, index) {
                      final fieldKey = fieldKeys[index];
                      final txtController = controller.fieldControllers[fieldKey];
                      if (txtController == null) return const SizedBox.shrink();

                      // Resolve label: search in activeFields, fallback to getFieldLabel
                      final matchingField = activeFields.firstWhereOrNull((f) => f.key == fieldKey);
                      final label = matchingField?.name ?? MeasurementFields.getFieldLabel(fieldKey);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildClothingTypeChip(
    BuildContext context, {
    required ClothingTypeEntity type,
    required bool isSelected,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF1E1E1E) : theme.cardColor),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(type.name),
              size: 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              type.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddClothingTypeButton(
    BuildContext context,
    ClothingTypeController clothingTypeCtrl,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showAddClothingTypeDialog(context, clothingTypeCtrl),
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        width: 84,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.grey.shade50,
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String name) {
    switch (name.toLowerCase()) {
      case 'shirt':
        return Icons.checkroom;
      case 'pant':
        return Icons.accessibility_new;
      case 'kurta':
        return Icons.brush;
      case 'blazer':
      case 'suit':
        return Icons.dry_cleaning;
      case 'sherwani':
        return Icons.auto_awesome;
      default:
        return Icons.style;
    }
  }

  void _showAddClothingTypeDialog(BuildContext context, ClothingTypeController ctrl) {
    final textCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Clothing Type'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: textCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Clothing Type Name',
                  hintText: 'e.g. Blazer, Sherwani, Waistcoat',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name.';
                  }
                  final trimmed = val.trim();
                  final isDup = ctrl.clothingTypes.any(
                      (t) => t.name.trim().toLowerCase() == trimmed.toLowerCase());
                  if (isDup) {
                    return 'A clothing type with this name already exists.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = textCtrl.text.trim();
                Get.back();
                await ctrl.addClothingType(name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddFieldDialog(
    BuildContext context,
    ClothingTypeController clothingTypeCtrl,
    MeasurementController measurementCtrl,
    String clothingTypeId,
  ) {
    final textCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Measurement Field'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: textCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Field Name',
                  hintText: 'e.g. Collar Round, Armhole, Cuff',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a field name.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = textCtrl.text.trim();
                Get.back();
                await clothingTypeCtrl.addField(clothingTypeId, name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
