import '../entities/measurement_entity.dart';
import '../repositories/measurement_repository.dart';

class UpdateMeasurement {
  final MeasurementRepository repository;

  UpdateMeasurement(this.repository);

  Future<void> call(String userId, String customerId, MeasurementEntity measurement) async {
    await repository.updateMeasurement(userId, customerId, measurement);
  }
}
