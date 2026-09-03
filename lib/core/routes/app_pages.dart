import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/add_edit_customer_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/measurements/presentation/pages/add_edit_measurement_page.dart';
import '../../features/measurements/presentation/pages/measurement_detail_page.dart';
import '../../features/measurements/presentation/pages/measurement_settings_page.dart';
import '../../features/measurements/presentation/pages/clothing_type_fields_page.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const customers = '/customers';
  static const addCustomer = '/customers/add';
  static const editCustomer = '/customers/edit';
  static const customerDetail = '/customers/detail';
  static const addMeasurement = '/measurements/add';
  static const measurementDetail = '/measurements/detail';
  static const measurementSettings = '/measurements/settings';
  static const clothingTypeFields = '/measurements/clothing-type-fields';
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) {
      return const RouteSettings(name: AppRoutes.login);
    }
    final authController = Get.find<AuthController>();
    final isAuthorized = authController.authStatus.value == AuthStatus.authorized &&
        authController.rxUser.value != null &&
        authController.rxUser.value!.isActive;

    if (!isAuthorized) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addCustomer,
      page: () => const AddEditCustomerPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editCustomer,
      page: () => const AddEditCustomerPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      page: () => const CustomerDetailPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addMeasurement,
      page: () => const AddEditMeasurementPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.measurementDetail,
      page: () => const MeasurementDetailPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.measurementSettings,
      page: () => const MeasurementSettingsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.clothingTypeFields,
      page: () => const ClothingTypeFieldsPage(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
