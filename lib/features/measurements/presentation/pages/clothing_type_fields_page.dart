import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/clothing_type_controller.dart';
import '../../domain/entities/clothing_type_entity.dart';
import '../../domain/entities/measurement_field_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/empty_state.dart';

class ClothingTypeFieldsPage extends StatelessWidget {
  const ClothingTypeFieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final ClothingTypeEntity clothingType = args['clothingType'] as ClothingTypeEntity;
    final clothingTypeCtrl = Get.find<ClothingTypeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${clothingType.name} Fields'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (clothingTypeCtrl.isSettingsFieldsLoading.value &&
              clothingTypeCtrl.settingsFields.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final fields = clothingTypeCtrl.allSettingsFieldsSorted;

          if (fields.isEmpty) {
            return EmptyState(
              icon: Icons.straighten_outlined,
              title: 'No Measurement Fields',
              description: 'Define the measurement fields (e.g. Length, Chest, Shoulder) for ${clothingType.name}.',
              actionText: 'Add Measurement Field',
              onActionPressed: () => _showAddFieldDialog(context, clothingTypeCtrl, clothingType.id),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            children: [
              // Informational Banner
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clothingType.isDefault
                              ? 'Default fields can be enabled or disabled. Custom fields can be edited or deleted.'
                              : 'Custom measurement fields for this clothing type.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Fields List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fields.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final field = fields[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: field.isActive
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.grey.shade200,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: field.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          field.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: field.isActive ? null : Colors.grey,
                            decoration: field.isActive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        if (field.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'Key: ${field.key}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    trailing: field.isDefault
                        ? Switch.adaptive(
                            value: field.isActive,
                            onChanged: (active) {
                              clothingTypeCtrl.toggleFieldActive(clothingType.id, field.id, active);
                            },
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Field Name',
                                onPressed: () => _showEditFieldDialog(
                                  context,
                                  clothingTypeCtrl,
                                  clothingType.id,
                                  field,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                tooltip: 'Delete Field',
                                onPressed: () => _showDeleteFieldConfirmation(
                                  context,
                                  clothingTypeCtrl,
                                  clothingType.id,
                                  field,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFieldDialog(context, clothingTypeCtrl, clothingType.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement Field'),
      ),
    );
  }

  void _showAddFieldDialog(BuildContext context, ClothingTypeController ctrl, String clothingTypeId) {
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
                  hintText: 'e.g. Collar Round, Bicep, Inseam',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a field name.';
                  }
                  final key = MeasurementFieldEntity.generateKey(val.trim());
                  if (key.isEmpty) {
                    return 'Invalid field name. Use letters and spaces.';
                  }
                  final isDup = ctrl.settingsFields.any((f) => f.key == key);
                  if (isDup) {
                    return 'A field with this name already exists.';
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
                await ctrl.addField(clothingTypeId, name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(
    BuildContext context,
    ClothingTypeController ctrl,
    String clothingTypeId,
    MeasurementFieldEntity field,
  ) {
    final textCtrl = TextEditingController(text: field.name);
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Field Name'),
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
                  labelText: 'Display Name',
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
                final newName = textCtrl.text.trim();
                Get.back();
                await ctrl.updateFieldName(clothingTypeId, field, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFieldConfirmation(
    BuildContext context,
    ClothingTypeController ctrl,
    String clothingTypeId,
    MeasurementFieldEntity field,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete "${field.name}"?'),
        content: const Text(
          'Are you sure you want to delete this custom field? Existing historical measurement records will still display values previously saved for this field.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteField(clothingTypeId, field.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
