import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/get_customers.dart';
import '../../domain/usecases/add_customer.dart';
import '../../domain/usecases/update_customer.dart';
import '../../domain/usecases/delete_customer.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:tailormate/features/measurements/presentation/controllers/measurement_controller.dart';
import '../../../../core/routes/app_pages.dart';

class CustomerController extends GetxController {
  final GetCustomers getCustomersUseCase;
  final AddCustomer addCustomerUseCase;
  final UpdateCustomer updateCustomerUseCase;
  final DeleteCustomer deleteCustomerUseCase;

  CustomerController({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
  });

  final AuthController _authController = Get.find<AuthController>();

  final RxList<CustomerEntity> allCustomers = <CustomerEntity>[].obs;
  final RxList<CustomerEntity> filteredCustomers = <CustomerEntity>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<CustomerEntity>>? _customersSubscription;

  // Controllers for Add/Edit Form
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final searchController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    
    // Listen to auth state changes to dynamically bind the customers stream
    ever(_authController.rxUser, (user) {
      if (user != null && user.isActive) {
        _customersSubscription?.cancel();
        _customersSubscription = getCustomersUseCase(user.uid).listen(
          (customers) {
            customers.sort((a, b) {
              final cmp = b.updatedAt.compareTo(a.updatedAt);
              if (cmp != 0) return cmp;
              return b.createdAt.compareTo(a.createdAt);
            });
            allCustomers.value = customers;
          },
          onError: (error) {
            debugPrint('Customers stream error: $error');
          },
        );
      } else {
        clearData();
      }
    });

    // Fallback: Bind stream immediately if user is already logged in at initialization
    final currentUser = _authController.rxUser.value;
    if (currentUser != null && currentUser.isActive) {
      _customersSubscription?.cancel();
      _customersSubscription = getCustomersUseCase(currentUser.uid).listen(
        (customers) {
          customers.sort((a, b) {
            final cmp = b.updatedAt.compareTo(a.updatedAt);
            if (cmp != 0) return cmp;
            return b.createdAt.compareTo(a.createdAt);
          });
          allCustomers.value = customers;
        },
        onError: (error) {
          debugPrint('Customers stream error: $error');
        },
      );
    }

    // Filter customers whenever the allCustomers list updates or searchQuery changes
    ever(allCustomers, (_) => _filterCustomers());
    debounce(searchQuery, (_) => _filterCustomers(), time: const Duration(milliseconds: 300));
  }

  void clearData() {
    _customersSubscription?.cancel();
    _customersSubscription = null;
    allCustomers.clear();
    filteredCustomers.clear();
  }

  @override
  void onClose() {
    clearData();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _filterCustomers() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredCustomers.assignAll(allCustomers);
    } else {
      final matches = allCustomers.where((customer) {
        final nameMatch = customer.name.toLowerCase().contains(query);
        final phoneMatch = customer.phone.contains(query);
        final locationMatch = customer.address?.toLowerCase().contains(query) ?? false;
        return nameMatch || phoneMatch || locationMatch;
      }).toList();
      filteredCustomers.assignAll(matches);
    }
  }

  void initForm(CustomerEntity? customer) {
    isLoading.value = false;
    if (customer != null) {
      nameController.text = customer.name;
      phoneController.text = customer.phone;
      emailController.text = customer.email ?? '';
      addressController.text = customer.address ?? '';
      notesController.text = customer.notes ?? '';
    } else {
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      notesController.clear();
    }
  }

  Future<void> saveCustomer(CustomerEntity? existingCustomer) async {
    if (!formKey.currentState!.validate()) return;

    final userId = _authController.rxUser.value?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not authenticated.');
      return;
    }

    try {
      isLoading.value = true;
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final email = emailController.text.trim().isEmpty ? null : emailController.text.trim();
      final address = addressController.text.trim().isEmpty ? null : addressController.text.trim();
      final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();

      // Prevent duplicate customer names and phone numbers
      final isDuplicate = allCustomers.any((c) =>
          c.id != (existingCustomer?.id ?? '') &&
          c.name.trim().toLowerCase() == name.toLowerCase() &&
          c.phone.trim() == phone);

      if (isDuplicate) {
        Get.snackbar(
          'Duplicate Customer',
          'A customer named "$name" with phone number "$phone" already exists.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFEF3C7), // Amber 100
          colorText: const Color(0xFF92400E), // Amber 800
        );
        isLoading.value = false;
        return;
      }

      if (existingCustomer == null) {
        // Create new customer
        final newCustomer = CustomerEntity(
          id: '',
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await addCustomerUseCase(userId, newCustomer);
        Get.back();
        Get.snackbar('Success', 'Customer added successfully.');
      } else {
        // Update existing customer
        final updatedCustomer = existingCustomer.copyWith(
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        await updateCustomerUseCase(userId, updatedCustomer);
        Get.back();
        // Update details page customer reference if visible
        if (Get.isRegistered<CustomerDetailPageController>()) {
          Get.find<CustomerDetailPageController>().updateCustomer(updatedCustomer);
        }
        Get.snackbar('Success', 'Customer updated successfully.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save customer data.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCustomerRecord(String customerId) async {
    final userId = _authController.rxUser.value?.uid;
    if (userId == null) return;

    try {
      isLoading.value = true;
      await deleteCustomerUseCase(userId, customerId);
      Get.until((route) => Get.currentRoute == AppRoutes.dashboard || Get.currentRoute == AppRoutes.customers);
      Get.snackbar('Success', 'Customer record deleted.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete customer.');
    } finally {
      isLoading.value = false;
    }
  }
}

// Separate simple controller for Detail page to prevent state mixing
class CustomerDetailPageController extends GetxController {
  final Rx<CustomerEntity> customer;
  CustomerDetailPageController(CustomerEntity initialCustomer) : customer = initialCustomer.obs;

  void updateCustomer(CustomerEntity updated) {
    customer.value = updated;
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<MeasurementController>()) {
      Get.find<MeasurementController>().loadHistory(customer.value.id);
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<MeasurementController>()) {
      Get.find<MeasurementController>().cancelHistorySubscription();
    }
    super.onClose();
  }
}
