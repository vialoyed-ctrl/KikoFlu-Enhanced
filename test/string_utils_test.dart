import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/string_utils.dart';

void main() {
  group('string utils', () {
    test('formatDuration keeps existing padded-hour default', () {
      expect(formatDuration(const Duration(seconds: 65)), '01:05');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    test('formatDuration can render compact hours for dense UI', () {
      expect(
        formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
          padHours: false,
        ),
        '1:02:03',
      );
    });

    test('formatDurationSeconds handles numeric API values', () {
      expect(formatDurationSeconds(null), '');
      expect(formatDurationSeconds(0), '');
      expect(formatDurationSeconds('12'), '');
      expect(formatDurationSeconds(65, padHours: false), '01:05');
      expect(formatDurationSeconds(3661.9, padHours: false), '1:01:01');
    });
  });
}
