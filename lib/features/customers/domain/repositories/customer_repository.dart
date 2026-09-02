import '../../domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Stream<List<CustomerEntity>> getCustomers(String userId);
  Future<void> addCustomer(String userId, CustomerEntity customer);
  Future<void> updateCustomer(String userId, CustomerEntity customer);
  Future<void> deleteCustomer(String userId, String customerId);
}
