import 'package:get/get.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:tailormate/features/customers/presentation/controllers/customer_controller.dart';
import 'package:tailormate/features/customers/domain/entities/customer_entity.dart';

class DashboardController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final CustomerController _customerController = Get.find<CustomerController>();

  // Reactive Stats
  RxInt get totalCustomers => _customerController.allCustomers.length.obs;

  bool get hasCustomers => _customerController.allCustomers.isNotEmpty;
  bool get hasMoreThanFive => _customerController.allCustomers.length > 5;
  int get totalCustomerCount => _customerController.allCustomers.length;

  // Strictly limited to latest 5 customers
  List<CustomerEntity> get recentCustomers {
    final list = _customerController.allCustomers;
    if (list.length > 5) {
      return list.sublist(0, 5);
    }
    return list;
  }

  String get userDisplayName => _authController.rxUser.value?.name ?? 'Tailor';
  String? get userPhotoUrl => _authController.rxUser.value?.photoUrl;

  void logout() {
    _authController.logout();
  }
}
