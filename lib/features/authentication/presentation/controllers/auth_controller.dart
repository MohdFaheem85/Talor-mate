import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../measurements/presentation/controllers/clothing_type_controller.dart';
import '../../../measurements/presentation/controllers/measurement_controller.dart';

class AuthController extends GetxController {
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final ObserveAuthState observeAuthStateUseCase;

  final Rxn<UserEntity> rxUser = Rxn<UserEntity>();
  final Rx<bool> isLoading = false.obs;

  AuthController({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.observeAuthStateUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    // Bind the auth state changes stream
    rxUser.bindStream(observeAuthStateUseCase());
    
    // Ever listener to navigate based on auth state changes
    ever(rxUser, _handleAuthRedirect);
  }

  void _handleAuthRedirect(UserEntity? user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  Future<void> login() async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      final user = await signInWithGoogleUseCase();
      if (user == null) {
        // User cancelled the login flow.
        isLoading.value = false;
        return;
      }
      // Successful login is handled automatically by the ever() listener
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String friendlyMessage = 'Authentication error occurred.';
      if (e.code == 'network-request-failed') {
        friendlyMessage = 'Network error. Please check your internet connection.';
      } else if (e.code == 'account-exists-with-different-credential') {
        friendlyMessage = 'An account already exists with a different credential.';
      }
      Get.snackbar(
        'Sign-in Failed',
        friendlyMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isLoading.value = false;
      debugPrint("GOOGLE SIGN IN ERROR: $e");
      Get.snackbar(
        'Sign-in Failed',
        'Could not complete Google Sign-In: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Proactively cancel all active Firestore snapshot listeners BEFORE revoking auth credentials
      if (Get.isRegistered<CustomerController>()) {
        Get.find<CustomerController>().clearData();
      }
      if (Get.isRegistered<ClothingTypeController>()) {
        Get.find<ClothingTypeController>().clearData();
      }
      if (Get.isRegistered<MeasurementController>()) {
        Get.find<MeasurementController>().clearData();
      }

      await signOutUseCase();
      // Successful logout is handled automatically by the ever() listener
    } catch (e) {
      Get.snackbar(
        'Logout Failed',
        'An error occurred during logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
