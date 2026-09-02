import '../../domain/entities/measurement_entity.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../datasources/measurement_remote_datasource.dart';
import '../models/measurement_model.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  final MeasurementRemoteDataSource remoteDataSource;

  MeasurementRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<MeasurementEntity>> getMeasurements(String userId, String customerId) {
    return remoteDataSource.getMeasurements(userId, customerId);
  }

  @override
  Future<void> addMeasurement(
    String userId,
    String customerId,
    MeasurementEntity measurement,
  ) async {
    final model = MeasurementModel.fromEntity(measurement);
    await remoteDataSource.addMeasurement(userId, customerId, model);
  }

  @override
  Future<void> updateMeasurement(
    String userId,
    String customerId,
    MeasurementEntity measurement,
  ) async {
    final model = MeasurementModel.fromEntity(measurement);
    await remoteDataSource.updateMeasurement(userId, customerId, model);
  }

  @override
  Future<void> deleteMeasurement(
    String userId,
    String customerId,
    String measurementId,
  ) async {
    await remoteDataSource.deleteMeasurement(userId, customerId, measurementId);
  }
}
