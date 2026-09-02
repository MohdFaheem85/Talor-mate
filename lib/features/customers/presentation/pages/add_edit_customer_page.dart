import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/offline_banner.dart';

class AddEditCustomerPage extends StatelessWidget {
  const AddEditCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerEntity? customer = Get.arguments as CustomerEntity?;
    final controller = Get.find<CustomerController>();
    
    // Initialize form fields
    controller.initForm(customer);

    final isEdit = customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                CustomTextField(
                  label: 'Customer Name *',
                  hint: 'Enter full name',
                  controller: controller.nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number *',
                  hint: 'Enter 10-digit phone number',
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email Address (Optional)',
                  hint: 'example@mail.com',
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Address (Optional)',
                  hint: 'Enter shop/home address',
                  controller: controller.addressController,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'E.g., Preferred style, urgent delivery',
                  controller: controller.notesController,
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Obx(() {
                  return CustomButton(
                    text: isEdit ? 'Update Customer' : 'Save Customer',
                    onPressed: () => controller.saveCustomer(customer),
                    isLoading: controller.isLoading.value,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
