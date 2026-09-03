import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import 'package:tailormate/features/customers/presentation/controllers/customer_controller.dart';
import 'package:tailormate/features/customers/presentation/widgets/customer_card.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/offline_banner.dart';
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
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Measurement Settings',
            onPressed: () => Get.toNamed(AppRoutes.measurementSettings),
          ),
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
            // Trigger reactive update across cached/synced customers
            customerCtrl.allCustomers.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                // Welcome header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: dashboardCtrl.userPhotoUrl != null
                          ? NetworkImage(dashboardCtrl.userPhotoUrl!)
                          : null,
                      child: dashboardCtrl.userPhotoUrl == null
                          ? Text(
                              dashboardCtrl.userDisplayName.isNotEmpty
                                  ? dashboardCtrl.userDisplayName[0].toUpperCase()
                                  : 'T',
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
                    // Total Customers Card (tap to View All Customers)
                    Expanded(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Get.toNamed(AppRoutes.customers),
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 13,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
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

                // Recent Customers Section
                Obx(() {
                  final recentList = dashboardCtrl.recentCustomers;
                  final hasCustomers = recentList.isNotEmpty;
                  final totalCount = dashboardCtrl.totalCustomerCount;

                  if (!hasCustomers) {
                    // Empty state when there are 0 customers (No "View All" shown)
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: 'No Customers Yet',
                      description: 'Add your first customer to start managing their clothing measurements.',
                      actionText: 'Add Customer',
                      onActionPressed: () => Get.toNamed(AppRoutes.addCustomer, arguments: null),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Recent Customers                     View All →
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Customers',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.customers),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Limited to at most 5 recent customer cards
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentList.length,
                        itemBuilder: (context, index) {
                          final customer = recentList[index];
                          return CustomerCard(customer: customer);
                        },
                      ),

                      // Optional bottom link if more than 5 customers exist
                      if (totalCount > 5) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.customers),
                            icon: const Icon(Icons.people_outline, size: 18),
                            label: Text(
                              'View All $totalCount Customers →',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
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
