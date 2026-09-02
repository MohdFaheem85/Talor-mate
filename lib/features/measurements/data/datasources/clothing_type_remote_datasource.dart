import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/clothing_type_model.dart';
import '../models/measurement_field_model.dart';
import '../../../../core/constants/constants.dart';

abstract class ClothingTypeRemoteDataSource {
  Stream<List<ClothingTypeModel>> getClothingTypes(String userId);
  Future<String> addClothingType(String userId, ClothingTypeModel type);
  Future<void> archiveClothingType(String userId, String typeId);
  Future<void> initializeDefaultsIfNeeded(String userId);
  Stream<List<MeasurementFieldModel>> getFields(String userId, String clothingTypeId);
  Future<void> addField(String userId, String clothingTypeId, MeasurementFieldModel field);
  Future<void> updateField(String userId, String clothingTypeId, MeasurementFieldModel field);
  Future<void> deleteField(String userId, String clothingTypeId, String fieldId);
  Future<void> toggleFieldActive(
      String userId, String clothingTypeId, String fieldId, bool isActive);
}

class ClothingTypeRemoteDataSourceImpl implements ClothingTypeRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _typesCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('clothingTypes');

  CollectionReference _fieldsCol(String userId, String clothingTypeId) =>
      _typesCol(userId).doc(clothingTypeId).collection('fields');

  // -- Clothing Types ----------------------------------------------------------

  @override
  Stream<List<ClothingTypeModel>> getClothingTypes(String userId) {
    return _typesCol(userId)
        .where('isActive', isEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
      final types =
          snap.docs.map((d) => ClothingTypeModel.fromSnapshot(d)).toList();

      // Sort: defaults first in canonical order, then custom alphabetically
      const defaultOrder = ['Shirt', 'Pant', 'Kurta'];
      types.sort((a, b) {
        final ai = defaultOrder.indexOf(a.name);
        final bi = defaultOrder.indexOf(b.name);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return a.name.compareTo(b.name);
      });
      return types;
    }).handleError((error) {
      debugPrint('ClothingTypeRemoteDataSource: types stream error: $error');
      return <ClothingTypeModel>[];
    });
  }

  @override
  Future<String> addClothingType(String userId, ClothingTypeModel type) async {
    try {
      final doc = _typesCol(userId).doc();
      await doc.set(type.toCreateMap()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: Add queued in local offline cache.');
        },
      );
      return doc.id;
    } catch (e) {
      debugPrint('addClothingType error: $e');
      throw Exception('Failed to add clothing type: $e');
    }
  }

  @override
  Future<void> archiveClothingType(String userId, String typeId) async {
    try {
      await _typesCol(userId).doc(typeId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: Archive queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('archiveClothingType error: $e');
      throw Exception('Failed to archive clothing type: $e');
    }
  }

  @override
  Future<void> initializeDefaultsIfNeeded(String userId) async {
    try {
      final existing = await _typesCol(userId).limit(1).get().timeout(
        const Duration(seconds: 2),
        onTimeout: () => _typesCol(userId).limit(1).get(const GetOptions(source: Source.cache)),
      );
      if (existing.docs.isNotEmpty) return; // Already seeded

      final batch = _firestore.batch();

      void addType(String name, List<String> fieldKeys) {
        final typeRef = _typesCol(userId).doc();
        batch.set(typeRef, {
          'name': name,
          'isDefault': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        for (var i = 0; i < fieldKeys.length; i++) {
          final fieldRef = _fieldsCol(userId, typeRef.id).doc();
          batch.set(fieldRef, {
            'name': MeasurementFields.getFieldLabel(fieldKeys[i]),
            'key': fieldKeys[i],
            'isDefault': true,
            'isActive': true,
            'displayOrder': i,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      addType('Shirt', MeasurementFields.shirtFields);
      addType('Pant', MeasurementFields.pantFields);
      addType('Kurta', MeasurementFields.kurtaFields);

      await batch.commit().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: Defaults seed queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('ClothingType: initializeDefaultsIfNeeded failed: $e');
    }
  }

  // -- Measurement Fields -------------------------------------------------------

  @override
  Stream<List<MeasurementFieldModel>> getFields(
      String userId, String clothingTypeId) {
    return _fieldsCol(userId, clothingTypeId)
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
      final fields =
          snap.docs.map((d) => MeasurementFieldModel.fromSnapshot(d)).toList();
      fields.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return fields;
    }).handleError((error) {
      debugPrint('ClothingTypeRemoteDataSource: fields stream error: $error');
      return <MeasurementFieldModel>[];
    });
  }

  @override
  Future<void> addField(
      String userId, String clothingTypeId, MeasurementFieldModel field) async {
    try {
      final doc = _fieldsCol(userId, clothingTypeId).doc();
      await doc.set(field.toCreateMap()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: addField queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('addField error: $e');
      throw Exception('Failed to add measurement field: $e');
    }
  }

  @override
  Future<void> updateField(
      String userId, String clothingTypeId, MeasurementFieldModel field) async {
    try {
      await _fieldsCol(userId, clothingTypeId)
          .doc(field.id)
          .update(field.toUpdateMap())
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: updateField queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('updateField error: $e');
      throw Exception('Failed to update measurement field: $e');
    }
  }

  @override
  Future<void> deleteField(
      String userId, String clothingTypeId, String fieldId) async {
    try {
      await _fieldsCol(userId, clothingTypeId).doc(fieldId).delete().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: deleteField queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('deleteField error: $e');
      throw Exception('Failed to delete measurement field: $e');
    }
  }

  @override
  Future<void> toggleFieldActive(
      String userId, String clothingTypeId, String fieldId, bool isActive) async {
    try {
      await _fieldsCol(userId, clothingTypeId).doc(fieldId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('ClothingType: toggleFieldActive queued in local offline cache.');
        },
      );
    } catch (e) {
      debugPrint('toggleFieldActive error: $e');
      throw Exception('Failed to toggle field active: $e');
    }
  }
}
