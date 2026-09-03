import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/clothing_type_controller.dart';
import '../../domain/entities/clothing_type_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/widgets/empty_state.dart';

class MeasurementSettingsPage extends StatelessWidget {
  const MeasurementSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clothingTypeCtrl = Get.find<ClothingTypeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Settings'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (clothingTypeCtrl.isLoadingTypes.value && clothingTypeCtrl.clothingTypes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final types = clothingTypeCtrl.clothingTypes;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            children: [
              // Header Card
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clothing Types & Fields',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Customize measurement fields for each garment or add new clothing types.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clothing Types',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddClothingTypeDialog(context, clothingTypeCtrl),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Type'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (types.isEmpty)
                EmptyState(
                  icon: Icons.checkroom_outlined,
                  title: 'No Clothing Types',
                  description: 'Add your first clothing type to start customizing measurement fields.',
                  actionText: 'Add Clothing Type',
                  onActionPressed: () => _showAddClothingTypeDialog(context, clothingTypeCtrl),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final type = types[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: type.isDefault
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                          child: Icon(
                            _getIconForType(type.name),
                            color: type.isDefault
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              type.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (type.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: const Text('Tap to configure fields'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!type.isDefault)
                              IconButton(
                                icon: const Icon(Icons.archive_outlined, size: 20, color: Colors.grey),
                                tooltip: 'Archive Clothing Type',
                                onPressed: () => _showArchiveConfirmation(context, clothingTypeCtrl, type),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          clothingTypeCtrl.loadSettingsFields(type.id);
                          Get.toNamed(
                            AppRoutes.clothingTypeFields,
                            arguments: {'clothingType': type},
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClothingTypeDialog(context, clothingTypeCtrl),
        icon: const Icon(Icons.add),
        label: const Text('Add Clothing Type'),
      ),
    );
  }

  IconData _getIconForType(String name) {
    switch (name.toLowerCase()) {
      case 'shirt':
        return Icons.checkroom;
      case 'pant':
        return Icons.accessibility;
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

  void _showArchiveConfirmation(BuildContext context, ClothingTypeController ctrl, ClothingTypeEntity type) {
    Get.dialog(
      AlertDialog(
        title: Text('Archive ${type.name}?'),
        content: Text(
          'This will remove "${type.name}" from new measurement forms. Existing measurement history will remain fully preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.archiveClothingType(type.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
