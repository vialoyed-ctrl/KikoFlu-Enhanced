import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/file_name_translation_service.dart';

Map<String, dynamic> fileItem(String title) {
  return {
    'type': 'audio',
    'title': title,
    'hash': title,
  };
}

Map<String, dynamic> folderItem(String title, List<dynamic> children) {
  return {
    'type': 'folder',
    'title': title,
    'children': children,
  };
}

void main() {
  group('FileNameTranslationService', () {
    test(
        'splits names into newline chunks without exceeding limit when possible',
        () {
      final chunks = FileNameTranslationService.splitNamesIntoChunks(
        ['aaaa', 'bbbb', 'cc'],
        maxChunkSize: 9,
      );

      expect(chunks, ['aaaa\nbbbb', 'cc']);
    });

    test('translates collected file tree names and reports progress', () async {
      final translatedChunks = <String>[];
      final progress = <String>[];
      final service = FileNameTranslationService(
        translate: (text, {sourceLang}) async {
          expect(sourceLang, 'ja');
          translatedChunks.add(text);
          return text.split('\n').map((line) => 'translated:$line').join('\n');
        },
        delay: (_) async {},
      );

      final result = await service.translateFileTree(
        fileTree: [
          folderItem('Disc', [
            fileItem('track01.mp3'),
            fileItem('track02.mp3'),
          ]),
        ],
        maxChunkSize: 100,
        onProgress: (current, total) => progress.add('$current/$total'),
      );

      expect(translatedChunks, ['Disc\ntrack01.mp3\ntrack02.mp3']);
      expect(progress, ['1/1']);
      expect(result.names, ['Disc', 'track01.mp3', 'track02.mp3']);
      expect(result.translations, {
        'Disc': 'translated:Disc',
        'track01.mp3': 'translated:track01.mp3',
        'track02.mp3': 'translated:track02.mp3',
      });
    });

    test('falls back to original chunk on translation failure', () async {
      final chunkErrors = <String>[];
      final service = FileNameTranslationService(
        translate: (text, {sourceLang}) async {
          if (text.contains('bad')) {
            throw StateError('failed');
          }
          return 'ok:$text';
        },
        delay: (_) async {},
      );

      final result = await service.translateFileTree(
        fileTree: [
          fileItem('good'),
          fileItem('bad'),
        ],
        maxChunkSize: 20,
        onChunkError: (index, error) {
          chunkErrors.add('$index:${error.runtimeType}');
        },
      );

      expect(chunkErrors, ['0:StateError']);
      expect(result.translations, {
        'good': 'good',
        'bad': 'bad',
      });
    });

    test('delays only between multiple chunks', () async {
      final delays = <Duration>[];
      final service = FileNameTranslationService(
        translate: (text, {sourceLang}) async => text,
        delay: (duration) async {
          delays.add(duration);
        },
      );

      await service.translateFileTree(
        fileTree: [
          fileItem('aaaa'),
          fileItem('bbbb'),
          fileItem('cccc'),
        ],
        maxChunkSize: 4,
        throttleDelay: const Duration(milliseconds: 12),
      );

      expect(delays, [
        const Duration(milliseconds: 12),
        const Duration(milliseconds: 12),
      ]);
    });
  });
}
