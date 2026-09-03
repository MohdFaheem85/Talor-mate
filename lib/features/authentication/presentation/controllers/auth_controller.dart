import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../../core/errors/failures.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../measurements/presentation/controllers/clothing_type_controller.dart';
import '../../../measurements/presentation/controllers/measurement_controller.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authorized,
  unauthorized, // Authenticated via Firebase but not in Firestore or not approved
  disabled,     // In Firestore with isActive == false
}

class AuthController extends GetxController {
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final ObserveAuthState observeAuthStateUseCase;
  final GetUserProfile getUserProfileUseCase;
  final GetCurrentUser getCurrentUserUseCase;

  final Rx<AuthStatus> authStatus = AuthStatus.initial.obs;
  final Rxn<UserEntity> rxUser = Rxn<UserEntity>();
  final Rx<bool> isLoading = false.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  AuthController({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.observeAuthStateUseCase,
    required this.getUserProfileUseCase,
    required this.getCurrentUserUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    checkInitialAuth();
  }

  @override
  void onClose() {
    _stopProfileListener();
    super.onClose();
  }

  /// Initial startup auth resolution. Runs once on app launch.
  Future<void> checkInitialAuth() async {
    if (Firebase.apps.isEmpty) {
      final user = getCurrentUserUseCase();
      if (user != null && user.isActive) {
        rxUser.value = user;
        authStatus.value = AuthStatus.authorized;
      } else {
        authStatus.value = AuthStatus.unauthenticated;
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      authStatus.value = AuthStatus.unauthenticated;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
      return;
    }

    try {
      // Query Firestore cache or network for user authorization document
      final userProfile = await getUserProfileUseCase(currentUser.uid);

      if (userProfile != null && userProfile.isActive) {
        rxUser.value = userProfile;
        authStatus.value = AuthStatus.authorized;
        _startProfileListener(currentUser.uid);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppRoutes.dashboard);
        });
      } else {
        final isDeactivated = userProfile != null && !userProfile.isActive;
        authStatus.value = isDeactivated ? AuthStatus.disabled : AuthStatus.unauthorized;
        await signOutUseCase();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppRoutes.login);
        });
      }
    } catch (e) {
      debugPrint('AuthController: initial auth check error: $e');
      await signOutUseCase().catchError((_) {});
      authStatus.value = AuthStatus.unauthenticated;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  /// Starts a real-time Firestore profile listener to immediately detect when
  /// an account is disabled (isActive: true -> false) or revoked while online.
  void _startProfileListener(String uid) {
    if (Firebase.apps.isEmpty) return;
    _stopProfileListener();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          // If document was removed on server (not an offline cache miss)
          if (!snapshot.metadata.isFromCache) {
            _handleRemoteRevocation('Your account record was removed by the administrator.');
          }
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        final isActive = data['isActive'] == true;
        if (!isActive) {
          _handleRemoteRevocation('Your account has been deactivated by the administrator.');
          return;
        }

        // Keep local user entity updated
        rxUser.value = UserModel.fromMap(data, uid);
      },
      onError: (error) {
        debugPrint('AuthController: profile listener error: $error');
        if (error.toString().contains('permission-denied')) {
          _handleRemoteRevocation('Access revoked by security policy.');
        }
      },
    );
  }

  void _stopProfileListener() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  /// Handles forced sign-out when the account is deactivated or revoked on server
  Future<void> _handleRemoteRevocation(String reason) async {
    debugPrint('AuthController: _handleRemoteRevocation: $reason');
    _stopProfileListener();

    // Clear dependent data controllers
    if (Get.isRegistered<CustomerController>()) {
      Get.find<CustomerController>().clearData();
    }
    if (Get.isRegistered<ClothingTypeController>()) {
      Get.find<ClothingTypeController>().clearData();
    }
    if (Get.isRegistered<MeasurementController>()) {
      Get.find<MeasurementController>().clearData();
    }

    rxUser.value = null;
    authStatus.value = AuthStatus.disabled;

    await signOutUseCase();

    if (Get.key.currentState != null) {
      Get.offAllNamed(AppRoutes.login);
    }

    if (Get.context != null && Get.key.currentState != null) {
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text('Account Disabled'),
            ],
          ),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      authStatus.value = AuthStatus.authenticating;

      final user = await signInWithGoogleUseCase();
      if (user == null) {
        // User cancelled the login flow
        isLoading.value = false;
        authStatus.value = AuthStatus.unauthenticated;
        return;
      }

      if (!user.isActive) {
        await signOutUseCase();
        authStatus.value = AuthStatus.disabled;
        _showAccessDeniedDialog(
          title: 'Account Disabled',
          message: 'Your account has been deactivated by the administrator.',
          email: user.email,
          uid: user.uid,
          isPending: false,
        );
        return;
      }

      // Successful authorization
      rxUser.value = user;
      authStatus.value = AuthStatus.authorized;
      _startProfileListener(user.uid);
      if (Get.key.currentState != null) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } on AccountUnauthorizedException catch (e) {
      authStatus.value = AuthStatus.unauthorized;
      rxUser.value = null;
      _showAccessDeniedDialog(
        title: 'Access Denied',
        message: 'Your Google account is not approved to access TailorMate.',
        email: e.email,
        uid: e.uid,
        isPending: true,
      );
    } on AccountDisabledException catch (e) {
      authStatus.value = AuthStatus.disabled;
      rxUser.value = null;
      _showAccessDeniedDialog(
        title: 'Account Disabled',
        message: 'Your account has been deactivated by the administrator.',
        email: e.email,
        uid: e.uid,
        isPending: false,
      );
    } on FirebaseAuthException catch (e) {
      authStatus.value = AuthStatus.unauthenticated;
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
      authStatus.value = AuthStatus.unauthenticated;
      debugPrint("GOOGLE SIGN IN ERROR: $e");
      Get.snackbar(
        'Sign-in Failed',
        'Could not complete Google Sign-In: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      _stopProfileListener();

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

      rxUser.value = null;
      authStatus.value = AuthStatus.unauthenticated;

      await signOutUseCase();
      if (Get.key.currentState != null) {
        Get.offAllNamed(AppRoutes.login);
      }
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

  void _showAccessDeniedDialog({
    required String title,
    required String message,
    required String email,
    required String uid,
    required bool isPending,
  }) {
    if (Get.context == null || Get.key.currentState == null) return;
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isPending ? Icons.lock_outline : Icons.block,
              color: isPending ? Colors.amber.shade800 : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: $email',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UID: $uid',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              const Text(
                'Please share your User ID or Email with the owner to request access.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
