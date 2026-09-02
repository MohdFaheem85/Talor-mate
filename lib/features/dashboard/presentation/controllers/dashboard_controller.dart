import 'package:get/get.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:tailormate/features/customers/presentation/controllers/customer_controller.dart';
import 'package:tailormate/features/customers/domain/entities/customer_entity.dart';

class DashboardController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final CustomerController _customerController = Get.find<CustomerController>();

  // Reactive Stats
  RxInt get totalCustomers => _customerController.allCustomers.length.obs;

  // RxList for Recent Customers
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
