import '../repositories/measurement_repository.dart';

class DeleteMeasurement {
  final MeasurementRepository repository;

  DeleteMeasurement(this.repository);

  Future<void> call(String userId, String customerId, String measurementId) async {
    await repository.deleteMeasurement(userId, customerId, measurementId);
  }
}
