class MeasurementFieldEntity {
  final String id;
  final String name;         // Display name, e.g. "Collar Round"
  final String key;          // Stable internal key, e.g. "collar_round"
  final bool isDefault;
  final bool isActive;       // false = hidden/disabled (default fields) or deleted (custom)
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeasurementFieldEntity({
    required this.id,
    required this.name,
    required this.key,
    required this.isDefault,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generates a stable database key from a user-visible display name.
  /// "Collar Round"    ? "collar_round"
  /// "Hip Width (Full)"? "hip_width_full"
  /// Keeps the key stable even if the display name is later renamed.
  static String generateKey(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  MeasurementFieldEntity copyWith({
    String? id,
    String? name,
    String? key,
    bool? isDefault,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementFieldEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      key: key ?? this.key,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
