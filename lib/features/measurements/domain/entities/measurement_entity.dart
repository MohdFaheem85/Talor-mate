class MeasurementEntity {
  final String id;
  final String? clothingTypeId; // Stable ID of clothing type
  final String clothingType; // Display name or canonical type e.g. 'Shirt', 'Pant', 'Kurta', 'Blazer'
  final String unit; // 'inch', 'cm'
  final Map<String, double> values;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeasurementEntity({
    required this.id,
    this.clothingTypeId,
    required this.clothingType,
    required this.unit,
    required this.values,
    required this.createdAt,
    required this.updatedAt,
  });

  MeasurementEntity copyWith({
    String? id,
    String? clothingTypeId,
    String? clothingType,
    String? unit,
    Map<String, double>? values,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementEntity(
      id: id ?? this.id,
      clothingTypeId: clothingTypeId ?? this.clothingTypeId,
      clothingType: clothingType ?? this.clothingType,
      unit: unit ?? this.unit,
      values: values ?? this.values,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
