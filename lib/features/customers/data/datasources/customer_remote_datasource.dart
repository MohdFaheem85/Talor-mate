import 'package:cloud_firestore/cloud_firestore.dart';
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
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomerModel.fromSnapshot(doc)).toList();
    });
  }

  @override
  Future<void> addCustomer(String userId, CustomerModel customer) async {
    try {
      await _customersCollection(userId).add(customer.toCreateMap());
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  @override
  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    try {
      await _customersCollection(userId).doc(customer.id).update(customer.toUpdateMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String userId, String customerId) async {
    try {
      await _customersCollection(userId).doc(customerId).delete();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }
}
