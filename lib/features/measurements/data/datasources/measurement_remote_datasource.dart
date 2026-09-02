import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/measurement_model.dart';

abstract class MeasurementRemoteDataSource {
  Stream<List<MeasurementModel>> getMeasurements(String userId, String customerId);
  Future<void> addMeasurement(String userId, String customerId, MeasurementModel measurement);
  Future<void> updateMeasurement(String userId, String customerId, MeasurementModel measurement);
  Future<void> deleteMeasurement(String userId, String customerId, String measurementId);
}

class MeasurementRemoteDataSourceImpl implements MeasurementRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _measurementsCollection(String userId, String customerId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customers')
        .doc(customerId)
        .collection('measurements');
  }

  @override
  Stream<List<MeasurementModel>> getMeasurements(String userId, String customerId) {
    return _measurementsCollection(userId, customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MeasurementModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Future<void> addMeasurement(
    String userId,
    String customerId,
    MeasurementModel measurement,
  ) async {
    try {
      await _measurementsCollection(userId, customerId).add(measurement.toCreateMap());
    } catch (e) {
      throw Exception('Failed to add measurement: $e');
    }
  }

  @override
  Future<void> updateMeasurement(
    String userId,
    String customerId,
    MeasurementModel measurement,
  ) async {
    try {
      await _measurementsCollection(userId, customerId)
          .doc(measurement.id)
          .update(measurement.toUpdateMap());
    } catch (e) {
      throw Exception('Failed to update measurement: $e');
    }
  }

  @override
  Future<void> deleteMeasurement(
    String userId,
    String customerId,
    String measurementId,
  ) async {
    try {
      await _measurementsCollection(userId, customerId).doc(measurementId).delete();
    } catch (e) {
      throw Exception('Failed to delete measurement: $e');
    }
  }
}
