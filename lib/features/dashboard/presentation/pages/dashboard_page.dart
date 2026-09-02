import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import 'package:tailormate/features/customers/presentation/controllers/customer_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/theme/theme_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure CustomerController is registered before DashboardController tries to find it
    final customerCtrl = Get.find<CustomerController>();
    final dashboardCtrl = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('TailorMate'),
        actions: [
          Obx(() {
            final themeService = Get.find<ThemeService>();
            return IconButton(
              icon: Icon(themeService.isDarkMode.value
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              tooltip: 'Toggle Theme',
              onPressed: () => themeService.toggleTheme(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log out',
            onPressed: () => _showLogoutConfirmation(context, dashboardCtrl),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Firestore sync happens automatically, but we trigger a reactive update
            customerCtrl.allCustomers.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: dashboardCtrl.userPhotoUrl != null
                          ? NetworkImage(dashboardCtrl.userPhotoUrl!)
                          : null,
                      child: dashboardCtrl.userPhotoUrl == null
                          ? Text(
                              dashboardCtrl.userDisplayName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          Text(
                            dashboardCtrl.userDisplayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats and Quick Actions
                Row(
                  children: [
                    // Total Customers Card
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Total Customers',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Obx(() {
                                return Text(
                                  '${dashboardCtrl.totalCustomers.value}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Quick Add Button
                    Expanded(
                      child: SizedBox(
                        height: 125,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.addCustomer, arguments: null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 32, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'Add Customer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 24),

                // List header: Search Results vs Recent Customers
                Obx(() {
                  final isSearching = customerCtrl.searchQuery.value.isNotEmpty;
                  return Text(
                    isSearching ? 'Search Results' : 'Recent Customers',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }),
                const SizedBox(height: 12),

                // Content list
                Obx(() {
                  final isSearching = customerCtrl.searchQuery.value.isNotEmpty;
                  final list = isSearching
                      ? customerCtrl.filteredCustomers
                      : dashboardCtrl.recentCustomers;

                  if (list.isEmpty) {
                    if (isSearching) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No matching customers found.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final customer = list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(customer.phone),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Get.toNamed(AppRoutes.customerDetail, arguments: customer);
                          },
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, DashboardController ctrl) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out from TailorMate?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
