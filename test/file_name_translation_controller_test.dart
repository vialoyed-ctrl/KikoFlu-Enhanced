import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/file_name_translation_controller.dart';

void main() {
  group('FileNameTranslationController', () {
    test('toggles existing translations and resolves display names', () {
      final controller = FileNameTranslationController();
      controller.translations['track01.mp3'] = 'translated track';

      expect(controller.displayName('track01.mp3'), 'track01.mp3');
      expect(controller.toggleExistingTranslations(), isTrue);
      expect(controller.showTranslation, isTrue);
      expect(controller.displayName('track01.mp3'), 'translated track');
      expect(controller.displayName('track02.mp3'), 'track02.mp3');
    });

    test('reports missing display names only while translations are visible',
        () {
      final controller = FileNameTranslationController();
      final queued = <String>[];

      expect(
        controller.displayName(
          'track01.mp3',
          onMissingTranslation: queued.add,
        ),
        'track01.mp3',
      );
      expect(queued, isEmpty);

      controller.showTranslation = true;
      expect(
        controller.displayName(
          'track01.mp3',
          onMissingTranslation: queued.add,
        ),
        'track01.mp3',
      );
      expect(queued, ['track01.mp3']);
    });

    test('bulk translation ignores stale progress and completion', () {
      final controller = FileNameTranslationController();

      final first = controller.beginBulkTranslation('Preparing');
      expect(controller.isBulkTranslating, isTrue);
      expect(controller.progress, 'Preparing');

      final second = controller.beginBulkTranslation('Restarting');
      expect(
        controller.updateBulkProgress(first, 'Stale progress'),
        isFalse,
      );
      expect(controller.progress, 'Restarting');
      expect(
        controller.completeBulkTranslation(first, const {'old': 'stale'}),
        isFalse,
      );
      expect(controller.translations, isEmpty);

      expect(
        controller.updateBulkProgress(second, 'Translating 1/1'),
        isTrue,
      );
      expect(
        controller
            .completeBulkTranslation(second, const {'name': 'translated'}),
        isTrue,
      );
      expect(controller.isBulkTranslating, isFalse);
      expect(controller.progress, isEmpty);
      expect(controller.showTranslation, isTrue);
      expect(controller.translations, {'name': 'translated'});
    });

    test('lazy translation deduplicates pending names and clears failures', () {
      final controller = FileNameTranslationController();

      final generation = controller.beginLazyTranslation('track01.mp3');
      expect(generation, isNotNull);
      expect(controller.pendingNames, {'track01.mp3'});
      expect(controller.beginLazyTranslation('track01.mp3'), isNull);

      expect(
        controller.failLazyTranslation(generation!, 'track01.mp3'),
        isTrue,
      );
      expect(controller.pendingNames, isEmpty);
      expect(controller.translations, isEmpty);
    });

    test('dispose invalidates pending lazy translations', () {
      final controller = FileNameTranslationController();

      final generation = controller.beginLazyTranslation('track01.mp3');
      controller.dispose();

      expect(
        controller.completeLazyTranslation(
          generation!,
          'track01.mp3',
          'translated track',
        ),
        isFalse,
      );
      expect(controller.pendingNames, isEmpty);
      expect(controller.translations, isEmpty);
      expect(controller.isBulkTranslating, isFalse);
    });
  });
}
