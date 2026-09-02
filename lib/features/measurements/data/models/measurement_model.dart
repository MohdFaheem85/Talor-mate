import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/measurement_entity.dart';

class MeasurementModel extends MeasurementEntity {
  const MeasurementModel({
    required super.id,
    required super.clothingType,
    required super.unit,
    required super.values,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MeasurementModel.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    
    // Safely parse values map converting any num to double
    final rawValues = map['values'] as Map<String, dynamic>? ?? {};
    final parsedValues = rawValues.map<String, double>((key, val) {
      return MapEntry(key, (val as num).toDouble());
    });

    return MeasurementModel(
      id: doc.id,
      clothingType: map['clothingType'] ?? '',
      unit: map['unit'] ?? '',
      values: parsedValues,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MeasurementModel.fromEntity(MeasurementEntity entity) {
    return MeasurementModel(
      id: entity.id,
      clothingType: entity.clothingType,
      unit: entity.unit,
      values: entity.values,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'clothingType': clothingType,
      'unit': unit,
      'values': values,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'clothingType': clothingType,
      'unit': unit,
      'values': values,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
