import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<CustomerEntity>> getCustomers(String userId) {
    return remoteDataSource.getCustomers(userId);
  }

  @override
  Future<void> addCustomer(String userId, CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await remoteDataSource.addCustomer(userId, model);
  }

  @override
  Future<void> updateCustomer(String userId, CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await remoteDataSource.updateCustomer(userId, model);
  }

  @override
  Future<void> deleteCustomer(String userId, String customerId) async {
    await remoteDataSource.deleteCustomer(userId, customerId);
  }
}
