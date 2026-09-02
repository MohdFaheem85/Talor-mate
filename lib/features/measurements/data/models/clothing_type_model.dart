import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/clothing_type_entity.dart';

class ClothingTypeModel extends ClothingTypeEntity {
  const ClothingTypeModel({
    required super.id,
    required super.name,
    required super.isDefault,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClothingTypeModel.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ClothingTypeModel(
      id: doc.id,
      name: map['name'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ClothingTypeModel.fromEntity(ClothingTypeEntity entity) {
    return ClothingTypeModel(
      id: entity.id,
      name: entity.name,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'isDefault': isDefault,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
