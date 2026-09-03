import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tailormate/features/customers/domain/entities/customer_entity.dart';
import 'package:tailormate/features/customers/presentation/controllers/customer_controller.dart';
import 'package:tailormate/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:tailormate/features/authentication/domain/entities/user_entity.dart';
import 'package:tailormate/features/authentication/domain/repositories/auth_repository.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_current_user.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_user_profile.dart';
import 'package:tailormate/features/authentication/domain/usecases/observe_auth_state.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_in_with_google.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_out.dart';
import 'package:tailormate/features/customers/domain/repositories/customer_repository.dart';
import 'package:tailormate/features/customers/domain/usecases/get_customers.dart';
import 'package:tailormate/features/customers/domain/usecases/add_customer.dart';
import 'package:tailormate/features/customers/domain/usecases/update_customer.dart';
import 'package:tailormate/features/customers/domain/usecases/delete_customer.dart';
import 'package:tailormate/core/routes/app_pages.dart';

class MockAuthRepo implements AuthRepository {
  final _user = UserEntity(
    uid: 'u1',
    name: 'Master Tailor',
    email: 'tailor@example.com',
    isActive: true,
    role: 'owner',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(_user);
  @override
  UserEntity? getCurrentUser() => _user;
  @override
  Future<UserEntity?> getUserProfile(String uid) async => _user;
  @override
  Future<UserEntity?> signInWithGoogle() async => _user;
  @override
  Future<void> signOut() async {}
}

class MockCustomerRepo implements CustomerRepository {
  final List<CustomerEntity> customers;
  MockCustomerRepo(this.customers);

  @override
  Stream<List<CustomerEntity>> getCustomers(String userId) => Stream.value(customers);
  @override
  Future<void> addCustomer(String userId, CustomerEntity customer) async {}
  @override
  Future<void> updateCustomer(String userId, CustomerEntity customer) async {}
  @override
  Future<void> deleteCustomer(String userId, String customerId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CustomerEntity makeCustomer(String id, String name, DateTime updatedTime) {
    return CustomerEntity(
      id: id,
      name: name,
      phone: '1234567890',
      createdAt: updatedTime,
      updatedAt: updatedTime,
    );
  }

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Dashboard Recent Customers & Limit Tests', () {
    test('Dashboard limits recent customers to strictly 5 when more than 5 exist', () async {
      final authRepo = MockAuthRepo();
      Get.put(AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(authRepo),
        signOutUseCase: SignOut(authRepo),
        observeAuthStateUseCase: ObserveAuthState(authRepo),
        getUserProfileUseCase: GetUserProfile(authRepo),
        getCurrentUserUseCase: GetCurrentUser(authRepo),
      ));

      final baseTime = DateTime(2026, 3, 1, 10, 0);
      final mockList = List.generate(
        8,
        (i) => makeCustomer('c$i', 'Customer $i', baseTime.add(Duration(hours: i))),
      );

      final customerRepo = MockCustomerRepo(mockList);
      final customerCtrl = Get.put(CustomerController(
        getCustomersUseCase: GetCustomers(customerRepo),
        addCustomerUseCase: AddCustomer(customerRepo),
        updateCustomerUseCase: UpdateCustomer(customerRepo),
        deleteCustomerUseCase: DeleteCustomer(customerRepo),
      ));

      // Allow stream to emit
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final dashboardCtrl = Get.put(DashboardController());

      expect(customerCtrl.allCustomers.length, 8);
      expect(dashboardCtrl.totalCustomers.value, 8);
      expect(dashboardCtrl.hasCustomers, isTrue);
      expect(dashboardCtrl.hasMoreThanFive, isTrue);
      expect(dashboardCtrl.recentCustomers.length, 5);

      // The recent 5 should be the newest ones: c7, c6, c5, c4, c3
      expect(dashboardCtrl.recentCustomers[0].id, 'c7');
      expect(dashboardCtrl.recentCustomers[1].id, 'c6');
      expect(dashboardCtrl.recentCustomers[2].id, 'c5');
      expect(dashboardCtrl.recentCustomers[3].id, 'c4');
      expect(dashboardCtrl.recentCustomers[4].id, 'c3');
    });

    test('Dashboard displays all customers when 5 or fewer exist without overflow', () async {
      final authRepo = MockAuthRepo();
      Get.put(AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(authRepo),
        signOutUseCase: SignOut(authRepo),
        observeAuthStateUseCase: ObserveAuthState(authRepo),
        getUserProfileUseCase: GetUserProfile(authRepo),
        getCurrentUserUseCase: GetCurrentUser(authRepo),
      ));

      final mockList = [
        makeCustomer('c1', 'Alice', DateTime(2026, 3, 1)),
        makeCustomer('c2', 'Bob', DateTime(2026, 3, 2)),
        makeCustomer('c3', 'Charlie', DateTime(2026, 3, 3)),
      ];

      final customerRepo = MockCustomerRepo(mockList);
      Get.put(CustomerController(
        getCustomersUseCase: GetCustomers(customerRepo),
        addCustomerUseCase: AddCustomer(customerRepo),
        updateCustomerUseCase: UpdateCustomer(customerRepo),
        deleteCustomerUseCase: DeleteCustomer(customerRepo),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final dashboardCtrl = Get.put(DashboardController());

      expect(dashboardCtrl.totalCustomers.value, 3);
      expect(dashboardCtrl.hasCustomers, isTrue);
      expect(dashboardCtrl.hasMoreThanFive, isFalse);
      expect(dashboardCtrl.recentCustomers.length, 3);
      // Newest first (Charlie, Bob, Alice)
      expect(dashboardCtrl.recentCustomers[0].name, 'Charlie');
      expect(dashboardCtrl.recentCustomers[1].name, 'Bob');
      expect(dashboardCtrl.recentCustomers[2].name, 'Alice');
    });

    test('Dashboard recognizes empty customer state correctly', () async {
      final authRepo = MockAuthRepo();
      Get.put(AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(authRepo),
        signOutUseCase: SignOut(authRepo),
        observeAuthStateUseCase: ObserveAuthState(authRepo),
        getUserProfileUseCase: GetUserProfile(authRepo),
        getCurrentUserUseCase: GetCurrentUser(authRepo),
      ));

      final customerRepo = MockCustomerRepo([]);
      Get.put(CustomerController(
        getCustomersUseCase: GetCustomers(customerRepo),
        addCustomerUseCase: AddCustomer(customerRepo),
        updateCustomerUseCase: UpdateCustomer(customerRepo),
        deleteCustomerUseCase: DeleteCustomer(customerRepo),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final dashboardCtrl = Get.put(DashboardController());

      expect(dashboardCtrl.totalCustomers.value, 0);
      expect(dashboardCtrl.hasCustomers, isFalse);
      expect(dashboardCtrl.hasMoreThanFive, isFalse);
      expect(dashboardCtrl.recentCustomers.isEmpty, isTrue);
    });

    test('Customer search matches by location/address', () async {
      final authRepo = MockAuthRepo();
      Get.put(AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(authRepo),
        signOutUseCase: SignOut(authRepo),
        observeAuthStateUseCase: ObserveAuthState(authRepo),
        getUserProfileUseCase: GetUserProfile(authRepo),
        getCurrentUserUseCase: GetCurrentUser(authRepo),
      ));

      final mockList = [
        CustomerEntity(
          id: 'c1',
          name: 'Rahul Sharma',
          phone: '9876543210',
          address: 'Bandra West, Mumbai',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
        ),
        CustomerEntity(
          id: 'c2',
          name: 'Amit Patel',
          phone: '9123456780',
          address: 'Civil Lines, Delhi',
          createdAt: DateTime(2026, 3, 2),
          updatedAt: DateTime(2026, 3, 2),
        ),
      ];

      final customerRepo = MockCustomerRepo(mockList);
      final customerCtrl = Get.put(CustomerController(
        getCustomersUseCase: GetCustomers(customerRepo),
        addCustomerUseCase: AddCustomer(customerRepo),
        updateCustomerUseCase: UpdateCustomer(customerRepo),
        deleteCustomerUseCase: DeleteCustomer(customerRepo),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Search by location "delhi"
      customerCtrl.searchQuery.value = 'delhi';
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(customerCtrl.filteredCustomers.length, 1);
      expect(customerCtrl.filteredCustomers.first.name, 'Amit Patel');

      // Search by location "bandra"
      customerCtrl.searchQuery.value = 'bandra';
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(customerCtrl.filteredCustomers.length, 1);
      expect(customerCtrl.filteredCustomers.first.name, 'Rahul Sharma');
    });

    test('Route registration contains AppRoutes.customers', () {
      expect(AppRoutes.customers, '/customers');
      final page = AppPages.pages.firstWhere((p) => p.name == AppRoutes.customers);
      expect(page, isNotNull);
      expect(page.middlewares?.length, 1);
    });
  });
}
