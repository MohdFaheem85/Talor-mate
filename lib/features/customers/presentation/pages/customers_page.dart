import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../widgets/customer_card.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/offline_banner.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customerCtrl = Get.find<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final total = customerCtrl.allCustomers.length;
          return Text('Customers ($total)');
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addCustomer, arguments: null),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Customer'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            customerCtrl.allCustomers.refresh();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                const SizedBox(height: 8),

                // Search Bar
                TextField(
                  controller: customerCtrl.searchController,
                  onChanged: (val) => customerCtrl.searchQuery.value = val,
                  decoration: InputDecoration(
                    hintText: 'Search customer by name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Obx(() {
                      if (customerCtrl.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            customerCtrl.searchQuery.value = '';
                            customerCtrl.searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Customer List
                Expanded(
                  child: Obx(() {
                    final isSearching = customerCtrl.searchQuery.value.isNotEmpty;
                    final list = isSearching
                        ? customerCtrl.filteredCustomers
                        : customerCtrl.allCustomers;

                    if (list.isEmpty) {
                      if (isSearching) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No matching customers found.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  customerCtrl.searchQuery.value = '';
                                  customerCtrl.searchController.clear();
                                },
                                child: const Text('Clear Search'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Customers Yet',
                          description: 'Add your first customer to start managing their clothing measurements.',
                          actionText: 'Add Customer',
                          onActionPressed: () => Get.toNamed(AppRoutes.addCustomer, arguments: null),
                        );
                      }
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                      itemBuilder: (context, index) {
                        final customer = list[index];
                        return CustomerCard(customer: customer);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
