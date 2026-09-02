import '../repositories/customer_repository.dart';

class DeleteCustomer {
  final CustomerRepository repository;

  DeleteCustomer(this.repository);

  Future<void> call(String userId, String customerId) async {
    await repository.deleteCustomer(userId, customerId);
  }
}
