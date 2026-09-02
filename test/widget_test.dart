import 'package:flutter_test/flutter_test.dart';
import 'package:tailormate/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('inchToCm converts correctly', () {
      expect(UnitConverter.inchToCm(1), 2.54);
      expect(UnitConverter.inchToCm(10), 25.4);
    });

    test('cmToInch converts correctly', () {
      expect(UnitConverter.cmToInch(2.54), closeTo(1.0, 0.001));
    });

    test('formatValue formats decimals correctly', () {
      expect(UnitConverter.formatValue(12.00), '12');
      expect(UnitConverter.formatValue(12.345), '12.35');
      expect(UnitConverter.formatValue(12.5), '12.5');
    });
  });
}
