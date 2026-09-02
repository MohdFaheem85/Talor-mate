import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../../domain/entities/customer_entity.dart';
import 'package:tailormate/features/measurements/presentation/controllers/measurement_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/widgets/empty_state.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final CustomerEntity initialCustomer = Get.arguments as CustomerEntity;
    
    // Bind detail controller
    final detailCtrl = Get.put(CustomerDetailPageController(initialCustomer));
    final customerCtrl = Get.find<CustomerController>();
    final measurementCtrl = Get.find<MeasurementController>();

    // Load measurements for this customer
    measurementCtrl.loadHistory(initialCustomer.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.toNamed(AppRoutes.editCustomer, arguments: detailCtrl.customer.value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(context, customerCtrl, initialCustomer.id),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Customer Info Card
            Obx(() {
              final c = detailCtrl.customer.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(c.phone, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    if (c.email != null && c.email!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(c.email!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ],
                    if (c.address != null && c.address!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.address!,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (c.notes != null && c.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(c.notes!, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // History Header
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.paddingMedium,
                right: AppDimensions.paddingMedium,
                top: AppDimensions.paddingMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Measurement History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.addMeasurement,
                        arguments: {'customerId': detailCtrl.customer.value.id, 'measurement': null},
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: Obx(() {
                final history = measurementCtrl.measurementHistory;
                if (history.isEmpty) {
                  return const EmptyState(
                    icon: Icons.square_foot_outlined,
                    title: 'No Measurements Yet',
                    description: 'Create clothing measurements to begin tracking history.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final m = history[index];
                    IconData clothingIcon;
                    String typeLabel = m.clothingType.toUpperCase();
                    if (m.clothingType == 'shirt') {
                      clothingIcon = Icons.checkroom;
                    } else if (m.clothingType == 'pant') {
                      clothingIcon = Icons.accessibility;
                    } else {
                      clothingIcon = Icons.brush; // Kurta fallback
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(clothingIcon, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(
                          '$typeLabel Measurement',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Recorded on ${_formatDate(m.createdAt)} in ${m.unit}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.measurementDetail,
                            arguments: {'customerId': detailCtrl.customer.value.id, 'measurement': m},
                          );
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CustomerController ctrl, String customerId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text(
          'This will permanently delete the customer record and all of their historical measurements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => ctrl.deleteCustomerRecord(customerId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
