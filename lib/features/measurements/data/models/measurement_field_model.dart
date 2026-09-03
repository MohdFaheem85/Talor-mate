import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/measurement_field_entity.dart';

class MeasurementFieldModel extends MeasurementFieldEntity {
  const MeasurementFieldModel({
    required super.id,
    required super.name,
    required super.key,
    required super.isDefault,
    required super.isActive,
    required super.displayOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MeasurementFieldModel.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return MeasurementFieldModel(
      id: doc.id,
      name: map['name'] as String? ?? '',
      key: map['key'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MeasurementFieldModel.fromEntity(MeasurementFieldEntity entity) {
    return MeasurementFieldModel(
      id: entity.id,
      name: entity.name,
      key: entity.key,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      displayOrder: entity.displayOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'key': key,
      'isDefault': isDefault,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'updatedAt': FieldValue.serverTimestamp(),
      // key is intentionally NOT updated (stable)
    };
  }
}
