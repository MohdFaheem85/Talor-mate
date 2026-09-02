import '../entities/measurement_entity.dart';

abstract class MeasurementRepository {
  Stream<List<MeasurementEntity>> getMeasurements(String userId, String customerId);
  Future<void> addMeasurement(String userId, String customerId, MeasurementEntity measurement);
  Future<void> updateMeasurement(String userId, String customerId, MeasurementEntity measurement);
  Future<void> deleteMeasurement(String userId, String customerId, String measurementId);
}
