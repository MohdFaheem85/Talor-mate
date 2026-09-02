import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomer {
  final CustomerRepository repository;

  UpdateCustomer(this.repository);

  Future<void> call(String userId, CustomerEntity customer) async {
    await repository.updateCustomer(userId, customer);
  }
}
