import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/utils/dates.dart';

void main() {
  test('addMonths moves forward and clamps to the month end', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    expect(addMonths(DateTime(2026, 12, 1), 12), DateTime(2027, 12, 1));
  });

  test('addMonths moves backward across year boundaries', () {
    expect(addMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
    expect(addMonths(DateTime(2026, 3, 10), -12), DateTime(2025, 3, 10));
    expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2026, 2, 1), -25), DateTime(2024, 1, 1));
  });
}
