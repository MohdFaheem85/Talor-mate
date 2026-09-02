import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_service.dart';
import 'core/services/sync_status_service.dart';
import 'core/routes/app_pages.dart';

// Authentication Layer Imports
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/sign_in_with_google.dart';
import 'features/authentication/domain/usecases/sign_out.dart';
import 'features/authentication/domain/usecases/observe_auth_state.dart';
import 'features/authentication/presentation/controllers/auth_controller.dart';

// Customers Layer Imports
import 'features/customers/data/datasources/customer_remote_datasource.dart';
import 'features/customers/data/repositories/customer_repository_impl.dart';
import 'features/customers/domain/repositories/customer_repository.dart';
import 'features/customers/domain/usecases/get_customers.dart';
import 'features/customers/domain/usecases/add_customer.dart';
import 'features/customers/domain/usecases/update_customer.dart';
import 'features/customers/domain/usecases/delete_customer.dart';
import 'features/customers/presentation/controllers/customer_controller.dart';

// Measurements Layer Imports
import 'features/measurements/data/datasources/measurement_remote_datasource.dart';
import 'features/measurements/data/repositories/measurement_repository_impl.dart';
import 'features/measurements/domain/repositories/measurement_repository.dart';
import 'features/measurements/domain/usecases/get_measurements.dart';
import 'features/measurements/domain/usecases/add_measurement.dart';
import 'features/measurements/domain/usecases/update_measurement.dart';
import 'features/measurements/domain/usecases/delete_measurement.dart';
import 'features/measurements/presentation/controllers/measurement_controller.dart';

// Clothing Types & Custom Fields Imports
import 'features/measurements/data/datasources/clothing_type_remote_datasource.dart';
import 'features/measurements/data/repositories/clothing_type_repository_impl.dart';
import 'features/measurements/domain/repositories/clothing_type_repository.dart';
import 'features/measurements/domain/usecases/get_clothing_types.dart';
import 'features/measurements/domain/usecases/add_clothing_type.dart';
import 'features/measurements/domain/usecases/archive_clothing_type.dart';
import 'features/measurements/domain/usecases/initialize_defaults.dart';
import 'features/measurements/domain/usecases/get_measurement_fields.dart';
import 'features/measurements/domain/usecases/add_measurement_field.dart';
import 'features/measurements/domain/usecases/update_measurement_field.dart';
import 'features/measurements/domain/usecases/delete_measurement_field.dart';
import 'features/measurements/domain/usecases/toggle_field_active.dart';
import 'features/measurements/presentation/controllers/clothing_type_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using platform specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence explicitly
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize ThemeService
  await Get.putAsync(() => ThemeService().init());

  // Setup DI injections
  _setupDependencyInjection();

  runApp(const MyApp());
}

void _setupDependencyInjection() {
  // 0. Sync Status Service
  Get.put(SyncStatusService(), permanent: true);

  // 1. Authentication Dependencies
  final authDataSource = Get.put<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(),
    permanent: true,
  );
  final authRepository = Get.put<AuthRepository>(
    AuthRepositoryImpl(remoteDataSource: authDataSource),
    permanent: true,
  );
  final signInWithGoogle = SignInWithGoogle(authRepository);
  final signOut = SignOut(authRepository);
  final observeAuthState = ObserveAuthState(authRepository);

  Get.put(
    AuthController(
      signInWithGoogleUseCase: signInWithGoogle,
      signOutUseCase: signOut,
      observeAuthStateUseCase: observeAuthState,
    ),
    permanent: true,
  );

  // 2. Customer Dependencies
  final customerDataSource = Get.put<CustomerRemoteDataSource>(
    CustomerRemoteDataSourceImpl(),
    permanent: true,
  );
  final customerRepository = Get.put<CustomerRepository>(
    CustomerRepositoryImpl(remoteDataSource: customerDataSource),
    permanent: true,
  );
  final getCustomers = GetCustomers(customerRepository);
  final addCustomer = AddCustomer(customerRepository);
  final updateCustomer = UpdateCustomer(customerRepository);
  final deleteCustomer = DeleteCustomer(customerRepository);

  Get.put(
    CustomerController(
      getCustomersUseCase: getCustomers,
      addCustomerUseCase: addCustomer,
      updateCustomerUseCase: updateCustomer,
      deleteCustomerUseCase: deleteCustomer,
    ),
    permanent: true,
  );

  // 3. Clothing Types & Fields Dependencies
  final clothingTypeDataSource = Get.put<ClothingTypeRemoteDataSource>(
    ClothingTypeRemoteDataSourceImpl(),
    permanent: true,
  );
  final clothingTypeRepository = Get.put<ClothingTypeRepository>(
    ClothingTypeRepositoryImpl(remoteDataSource: clothingTypeDataSource),
    permanent: true,
  );
  final getClothingTypes = GetClothingTypes(clothingTypeRepository);
  final addClothingType = AddClothingType(clothingTypeRepository);
  final archiveClothingType = ArchiveClothingType(clothingTypeRepository);
  final initializeDefaults = InitializeDefaults(clothingTypeRepository);
  final getMeasurementFields = GetMeasurementFields(clothingTypeRepository);
  final addMeasurementField = AddMeasurementField(clothingTypeRepository);
  final updateMeasurementField = UpdateMeasurementField(clothingTypeRepository);
  final deleteMeasurementField = DeleteMeasurementField(clothingTypeRepository);
  final toggleFieldActive = ToggleFieldActive(clothingTypeRepository);

  Get.put(
    ClothingTypeController(
      getClothingTypesUseCase: getClothingTypes,
      addClothingTypeUseCase: addClothingType,
      archiveClothingTypeUseCase: archiveClothingType,
      initializeDefaultsUseCase: initializeDefaults,
      getMeasurementFieldsUseCase: getMeasurementFields,
      addMeasurementFieldUseCase: addMeasurementField,
      updateMeasurementFieldUseCase: updateMeasurementField,
      deleteMeasurementFieldUseCase: deleteMeasurementField,
      toggleFieldActiveUseCase: toggleFieldActive,
    ),
    permanent: true,
  );

  // 4. Measurement Dependencies
  final measurementDataSource = Get.put<MeasurementRemoteDataSource>(
    MeasurementRemoteDataSourceImpl(),
    permanent: true,
  );
  final measurementRepository = Get.put<MeasurementRepository>(
    MeasurementRepositoryImpl(remoteDataSource: measurementDataSource),
    permanent: true,
  );
  final getMeasurements = GetMeasurements(measurementRepository);
  final addMeasurement = AddMeasurement(measurementRepository);
  final updateMeasurement = UpdateMeasurement(measurementRepository);
  final deleteMeasurement = DeleteMeasurement(measurementRepository);

  Get.put(
    MeasurementController(
      getMeasurementsUseCase: getMeasurements,
      addMeasurementUseCase: addMeasurement,
      updateMeasurementUseCase: updateMeasurement,
      deleteMeasurementUseCase: deleteMeasurement,
    ),
    permanent: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Obx(() => GetMaterialApp(
      title: 'TailorMate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    ));
  }
}
