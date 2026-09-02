import '../entities/measurement_entity.dart';
import '../repositories/measurement_repository.dart';

class AddMeasurement {
  final MeasurementRepository repository;

  AddMeasurement(this.repository);

  Future<void> call(String userId, String customerId, MeasurementEntity measurement) async {
    await repository.addMeasurement(userId, customerId, measurement);
  }
}
