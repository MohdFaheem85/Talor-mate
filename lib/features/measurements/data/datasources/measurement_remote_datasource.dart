import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) => MeasurementModel.fromSnapshot(doc)).toList();
    }).handleError((error) {
      debugPrint('MeasurementRemoteDataSource: stream error: $error');
      return <MeasurementModel>[];
    });
  }

  @override
  Future<void> addMeasurement(
    String userId,
    String customerId,
    MeasurementModel measurement,
  ) async {
    try {
      final docRef = _measurementsCollection(userId, customerId).doc();
      await docRef.set(measurement.toCreateMap()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('MeasurementRemoteDataSource: Write queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('addMeasurement error: $e');
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
          .update(measurement.toUpdateMap())
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('MeasurementRemoteDataSource: Update queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('updateMeasurement error: $e');
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
      await _measurementsCollection(userId, customerId)
          .doc(measurementId)
          .delete()
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('MeasurementRemoteDataSource: Delete queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('deleteMeasurement error: $e');
      throw Exception('Failed to delete measurement: $e');
    }
  }
}
