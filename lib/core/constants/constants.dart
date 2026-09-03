class AppColors {
  static const primaryHex = 0xFF6366F1; // Indigo 500
  static const secondaryHex = 0xFF10B981; // Emerald 500
  static const backgroundLightHex = 0xFFF9FAFB; // Gray 50
  static const backgroundDarkHex = 0xFF111827; // Gray 900
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
}

class MeasurementFields {
  static const String shirt = 'shirt';
  static const String pant = 'pant';
  static const String kurta = 'kurta';

  static const String unitInch = 'inch';
  static const String unitCm = 'cm';

  static const List<String> shirtFields = [
    'length',
    'chest',
    'waist',
    'shoulder',
    'sleeve',
    'neck',
    'armhole',
    'cuff',
    'bicep',
  ];

  static const List<String> pantFields = [
    'length',
    'waist',
    'hip',
    'thigh',
    'knee',
    'bottom',
    'inseam',
    'rise',
  ];

  static const List<String> kurtaFields = [
    'length',
    'chest',
    'waist',
    'hip',
    'shoulder',
    'sleeve',
    'neck',
    'armhole',
  ];

  static List<String> getFieldsForType(String type) {
    switch (type.toLowerCase()) {
      case shirt:
        return shirtFields;
      case pant:
        return pantFields;
      case kurta:
        return kurtaFields;
      default:
        return [];
    }
  }

  static String getFieldLabel(String field) {
    if (field.isEmpty) return field;
    switch (field) {
      case 'length': return 'Length';
      case 'chest': return 'Chest';
      case 'waist': return 'Waist';
      case 'shoulder': return 'Shoulder';
      case 'sleeve': return 'Sleeve';
      case 'neck': return 'Neck';
      case 'armhole': return 'Armhole';
      case 'cuff': return 'Cuff';
      case 'bicep': return 'Bicep';
      case 'hip': return 'Hip';
      case 'thigh': return 'Thigh';
      case 'knee': return 'Knee';
      case 'bottom': return 'Bottom';
      case 'inseam': return 'Inseam';
      case 'rise': return 'Rise';
      default:
        return field
            .split(RegExp(r'[_\s]+'))
            .where((s) => s.isNotEmpty)
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' ');
    }
  }
}
