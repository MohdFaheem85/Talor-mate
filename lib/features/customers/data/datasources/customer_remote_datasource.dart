import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Stream<List<CustomerModel>> getCustomers(String userId);
  Future<void> addCustomer(String userId, CustomerModel customer);
  Future<void> updateCustomer(String userId, CustomerModel customer);
  Future<void> deleteCustomer(String userId, String customerId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _customersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('customers');
  }

  @override
  Stream<List<CustomerModel>> getCustomers(String userId) {
    return _customersCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomerModel.fromSnapshot(doc)).toList();
    }).handleError((error) {
      debugPrint('CustomerRemoteDataSource: stream error: $error');
      return <CustomerModel>[];
    });
  }

  @override
  Future<void> addCustomer(String userId, CustomerModel customer) async {
    try {
      final docRef = _customersCollection(userId).doc();
      await docRef.set(customer.toCreateMap()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('CustomerRemoteDataSource: Write queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('addCustomer error: $e');
      throw Exception('Failed to add customer: $e');
    }
  }

  @override
  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    try {
      await _customersCollection(userId)
          .doc(customer.id)
          .update(customer.toUpdateMap())
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('CustomerRemoteDataSource: Update queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('updateCustomer error: $e');
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String userId, String customerId) async {
    try {
      await _customersCollection(userId)
          .doc(customerId)
          .delete()
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('CustomerRemoteDataSource: Delete queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('deleteCustomer error: $e');
      throw Exception('Failed to delete customer: $e');
    }
  }
}
