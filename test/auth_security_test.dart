import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tailormate/core/errors/failures.dart';
import 'package:tailormate/features/authentication/domain/entities/user_entity.dart';
import 'package:tailormate/features/authentication/data/models/user_model.dart';
import 'package:tailormate/features/authentication/domain/repositories/auth_repository.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_in_with_google.dart';
import 'package:tailormate/features/authentication/domain/usecases/sign_out.dart';
import 'package:tailormate/features/authentication/domain/usecases/observe_auth_state.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_user_profile.dart';
import 'package:tailormate/features/authentication/domain/usecases/get_current_user.dart';
import 'package:tailormate/features/authentication/presentation/controllers/auth_controller.dart';

class MockAuthSecurityRepository implements AuthRepository {
  UserEntity? mockUser;
  bool signOutCalled = false;

  MockAuthSecurityRepository({this.mockUser});

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(mockUser);

  @override
  UserEntity? getCurrentUser() => mockUser;

  @override
  Future<UserEntity?> signInWithGoogle() async {
    if (mockUser == null) {
      throw const AccountUnauthorizedException(
        email: 'unapproved@example.com',
        uid: 'unapproved_uid',
      );
    }
    if (!mockUser!.isActive) {
      throw const AccountDisabledException(
        email: 'disabled@example.com',
        uid: 'disabled_uid',
      );
    }
    return mockUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    if (mockUser != null && mockUser!.uid == uid) {
      return mockUser;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserModel & UserEntity Security Properties', () {
    final now = DateTime(2026, 1, 1);

    test('isOwner returns true only when role is owner', () {
      final ownerUser = UserEntity(
        uid: 'owner_1',
        name: 'Master Tailor',
        email: 'owner@example.com',
        isActive: true,
        role: 'owner',
        createdAt: now,
        updatedAt: now,
      );

      final regularUser = UserEntity(
        uid: 'user_1',
        name: 'Assistant Tailor',
        email: 'assistant@example.com',
        isActive: true,
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );

      expect(ownerUser.isOwner, isTrue);
      expect(regularUser.isOwner, isFalse);
    });

    test('UserModel.fromMap defaults isActive to false and role to user if missing', () {
      final model = UserModel.fromMap({
        'name': 'Test',
        'email': 'test@example.com',
      }, 'uid_123');

      expect(model.isActive, isFalse);
      expect(model.role, equals('user'));
      expect(model.isOwner, isFalse);
    });

    test('UserModel.fromMap correctly parses active owner document', () {
      final model = UserModel.fromMap({
        'name': 'Owner Admin',
        'email': 'admin@tailormate.com',
        'isActive': true,
        'role': 'owner',
      }, 'admin_uid');

      expect(model.isActive, isTrue);
      expect(model.role, equals('owner'));
      expect(model.isOwner, isTrue);
    });

    test('UserModel.toMap preserves isActive and role fields accurately', () {
      final model = UserModel(
        uid: 'u1',
        name: 'John',
        email: 'john@example.com',
        isActive: true,
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['isActive'], isTrue);
      expect(map['role'], equals('user'));
    });
  });

  group('AuthController Authorization States & Gates', () {
    final now = DateTime(2026, 1, 1);

    tearDown(() {
      Get.reset();
    });

    test('Startup with approved active user initializes in authorized status', () async {
      final activeUser = UserEntity(
        uid: 'approved_uid',
        name: 'Approved Tailor',
        email: 'approved@example.com',
        isActive: true,
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );

      final repo = MockAuthSecurityRepository(mockUser: activeUser);
      final controller = AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(repo),
        signOutUseCase: SignOut(repo),
        observeAuthStateUseCase: ObserveAuthState(repo),
        getUserProfileUseCase: GetUserProfile(repo),
        getCurrentUserUseCase: GetCurrentUser(repo),
      );
      await controller.checkInitialAuth();

      expect(controller.authStatus.value, equals(AuthStatus.authorized));
      expect(controller.rxUser.value, isNotNull);
      expect(controller.rxUser.value!.uid, equals('approved_uid'));
      expect(controller.rxUser.value!.isActive, isTrue);
    });

    test('Startup with unapproved user initializes in unauthenticated status and denies access', () async {
      final repo = MockAuthSecurityRepository(mockUser: null);
      final controller = AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(repo),
        signOutUseCase: SignOut(repo),
        observeAuthStateUseCase: ObserveAuthState(repo),
        getUserProfileUseCase: GetUserProfile(repo),
        getCurrentUserUseCase: GetCurrentUser(repo),
      );
      await controller.checkInitialAuth();

      expect(controller.authStatus.value, equals(AuthStatus.unauthenticated));
      expect(controller.rxUser.value, isNull);
    });

    test('Login attempt by unapproved account catches AccountUnauthorizedException and remains unauthorized', () async {
      final repo = MockAuthSecurityRepository(mockUser: null);
      final controller = AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(repo),
        signOutUseCase: SignOut(repo),
        observeAuthStateUseCase: ObserveAuthState(repo),
        getUserProfileUseCase: GetUserProfile(repo),
        getCurrentUserUseCase: GetCurrentUser(repo),
      );

      await controller.login();

      expect(controller.authStatus.value, equals(AuthStatus.unauthorized));
      expect(controller.rxUser.value, isNull);
    });

    test('Login attempt by deactivated account catches AccountDisabledException and transitions to disabled status', () async {
      final deactivatedUser = UserEntity(
        uid: 'deactivated_uid',
        name: 'Ex Tailor',
        email: 'disabled@example.com',
        isActive: false,
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );

      final repo = MockAuthSecurityRepository(mockUser: deactivatedUser);
      final controller = AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(repo),
        signOutUseCase: SignOut(repo),
        observeAuthStateUseCase: ObserveAuthState(repo),
        getUserProfileUseCase: GetUserProfile(repo),
        getCurrentUserUseCase: GetCurrentUser(repo),
      );

      await controller.login();

      expect(controller.authStatus.value, equals(AuthStatus.disabled));
      expect(controller.rxUser.value, isNull);
    });

    test('Logout clears user, cancels profile listeners, and resets status to unauthenticated', () async {
      final activeUser = UserEntity(
        uid: 'user_to_logout',
        name: 'Active Tailor',
        email: 'active@example.com',
        isActive: true,
        role: 'user',
        createdAt: now,
        updatedAt: now,
      );

      final repo = MockAuthSecurityRepository(mockUser: activeUser);
      final controller = AuthController(
        signInWithGoogleUseCase: SignInWithGoogle(repo),
        signOutUseCase: SignOut(repo),
        observeAuthStateUseCase: ObserveAuthState(repo),
        getUserProfileUseCase: GetUserProfile(repo),
        getCurrentUserUseCase: GetCurrentUser(repo),
      );
      await controller.checkInitialAuth();

      expect(controller.authStatus.value, equals(AuthStatus.authorized));

      await controller.logout();

      expect(controller.authStatus.value, equals(AuthStatus.unauthenticated));
      expect(controller.rxUser.value, isNull);
      expect(repo.signOutCalled, isTrue);
    });
  });
}
