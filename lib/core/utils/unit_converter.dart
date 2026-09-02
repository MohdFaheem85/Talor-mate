class UnitConverter {
  /// Converts inches to centimeters (1 inch = 2.54 cm).
  static double inchToCm(double inches) {
    return inches * 2.54;
  }

  /// Converts centimeters to inches.
  static double cmToInch(double cm) {
    return cm / 2.54;
  }

  /// Formats double value cleanly to display on UI.
  /// Trims redundant trailing decimals or trailing zeros.
  static String formatValue(double value) {
    // If it's a whole number, display it as an integer.
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    
    // Otherwise limit to 2 decimal places and trim trailing zeros.
    String formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    if (formatted.endsWith('0') && formatted.contains('.')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// Safely parses a double from input, returns null if invalid.
  static double? tryParse(String val) {
    if (val.trim().isEmpty) return null;
    return double.tryParse(val.trim());
  }
}
