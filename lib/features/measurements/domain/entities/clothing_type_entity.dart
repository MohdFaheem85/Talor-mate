class ClothingTypeEntity {
  final String id;
  final String name;
  final bool isDefault;
  final bool isActive; // false = soft-deleted / archived
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClothingTypeEntity({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  ClothingTypeEntity copyWith({
    String? id,
    String? name,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClothingTypeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
