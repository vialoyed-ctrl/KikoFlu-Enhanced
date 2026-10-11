import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/work.dart';

void main() {
  group('Work displayId', () {
    test('uses source_id from official API when present', () {
      final work = Work.fromJson(const {
        'id': 100000061,
        'title': '榊木春乃はアナタだけの配信者',
        'source_id': 'VJ01003041',
      });

      expect(work.sourceId, 'VJ01003041');
      expect(work.displayId, 'VJ01003041');
      expect(work.toJson()['source_id'], 'VJ01003041');
    });

    test('trims source_id before displaying it', () {
      const work = Work(
        id: 654321,
        title: 'Trim me',
        sourceId: '  BJ654321  ',
      );

      expect(work.displayId, 'BJ654321');
    });

    test('falls back to formatted RJ code for legacy payloads', () {
      const workWithoutSourceId = Work(id: 12345, title: 'Legacy');
      const workWithBlankSourceId = Work(
        id: 123456,
        title: 'Blank source id',
        sourceId: '   ',
      );

      expect(workWithoutSourceId.displayId, 'RJ012345');
      expect(workWithBlankSourceId.displayId, 'RJ123456');
    });

    test('copyWith can update source_id display', () {
      const work = Work(id: 12345, title: 'Original');

      expect(work.copyWith(sourceId: 'VJ012345').displayId, 'VJ012345');
    });
  });
}
