import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/customers/presentation/pages/add_edit_customer_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/measurements/presentation/pages/add_edit_measurement_page.dart';
import '../../features/measurements/presentation/pages/measurement_detail_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const addCustomer = '/customers/add';
  static const editCustomer = '/customers/edit';
  static const customerDetail = '/customers/detail';
  static const addMeasurement = '/measurements/add';
  static const measurementDetail = '/measurements/detail';
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
  ];
}
