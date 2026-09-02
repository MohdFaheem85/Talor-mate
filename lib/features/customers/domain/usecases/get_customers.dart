import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomers {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  Stream<List<CustomerEntity>> call(String userId) {
    return repository.getCustomers(userId);
  }
}
