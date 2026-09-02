import '../entities/measurement_entity.dart';
import '../repositories/measurement_repository.dart';

class GetMeasurements {
  final MeasurementRepository repository;

  GetMeasurements(this.repository);

  Stream<List<MeasurementEntity>> call(String userId, String customerId) {
    return repository.getMeasurements(userId, customerId);
  }
}
