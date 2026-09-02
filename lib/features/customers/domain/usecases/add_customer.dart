import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class AddCustomer {
  final CustomerRepository repository;

  AddCustomer(this.repository);

  Future<void> call(String userId, CustomerEntity customer) async {
    await repository.addCustomer(userId, customer);
  }
}
