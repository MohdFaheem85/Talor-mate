class MeasurementEntity {
  final String id;
  final String clothingType; // 'shirt', 'pant', 'kurta'
  final String unit; // 'inch', 'cm'
  final Map<String, double> values;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeasurementEntity({
    required this.id,
    required this.clothingType,
    required this.unit,
    required this.values,
    required this.createdAt,
    required this.updatedAt,
  });

  MeasurementEntity copyWith({
    String? id,
    String? clothingType,
    String? unit,
    Map<String, double>? values,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementEntity(
      id: id ?? this.id,
      clothingType: clothingType ?? this.clothingType,
      unit: unit ?? this.unit,
      values: values ?? this.values,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
