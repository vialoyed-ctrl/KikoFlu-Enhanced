import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/work_id_parser.dart';

void main() {
  group('WorkIdParser', () {
    test('extracts RJ ids case-insensitively', () {
      expect(
        WorkIdParser.extractRJIds('RJ123456 and rj233333'),
        ['RJ123456', 'RJ233333'],
      );
    });

    test('deduplicates ids while preserving first occurrence order', () {
      expect(
        WorkIdParser.extractRJIds('rj1 RJ2 RJ1 rj3 RJ2'),
        ['RJ1', 'RJ2', 'RJ3'],
      );
    });

    test('returns empty list when no ids are present', () {
      expect(WorkIdParser.extractRJIds('hello 123456'), isEmpty);
      expect(WorkIdParser.extractRJIds(''), isEmpty);
    });
  });
}
