import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:kikoeru_flutter/src/services/subtitle_availability_scanner.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_service.dart';

Map<String, dynamic> fileItem(String title, {String type = 'file'}) {
  return {
    'type': type,
    'title': title,
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
  group('SubtitleAvailabilityScanner', () {
    test('generates possible work folder names', () {
      expect(
        SubtitleAvailabilityScanner.possibleWorkFolderNames(123456),
        [
          'RJ123456',
          'RJ0123456',
          'BJ123456',
          'BJ0123456',
          'VJ123456',
          'VJ0123456'
        ],
      );
    });

    test('collects audio titles recursively from file tree', () {
      final tree = [
        folderItem('Main', [
          fileItem('track01.flac'),
          fileItem('script.srt', type: 'text'),
          folderItem('Bonus', [fileItem('bonus.wav')]),
        ]),
      ];

      expect(
        SubtitleAvailabilityScanner.collectAudioTitles(tree),
        {'track01.flac', 'bonus.wav'},
      );
    });

    test('finds audio files with matching subtitles in library folders',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'kikoflu_subtitle_scanner_test_',
      );

      try {
        final parsedDir = Directory(
          p.join(
            tempDir.path,
            SubtitleLibraryService.parsedFolderName,
            'RJ123456',
          ),
        );
        await parsedDir.create(recursive: true);
        await File(p.join(parsedDir.path, 'track01.srt')).writeAsString('sub');
        await File(p.join(parsedDir.path, 'unmatched.srt'))
            .writeAsString('sub');

        final tree = [
          folderItem('Main', [
            fileItem('track01.flac'),
            fileItem('track02.wav'),
          ]),
        ];

        final matches = await const SubtitleAvailabilityScanner()
            .findAudioTitlesWithSubtitles(
          libraryDir: tempDir,
          workId: 123456,
          fileTree: tree,
        );

        expect(matches, {'track01.flac'});
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns empty set when library directory is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'kikoflu_missing_subtitle_scanner_test_',
      );
      final missingDir = Directory(p.join(tempDir.path, 'missing'));

      try {
        final matches = await const SubtitleAvailabilityScanner()
            .findAudioTitlesWithSubtitles(
          libraryDir: missingDir,
          workId: 123456,
          fileTree: [fileItem('track01.flac')],
        );

        expect(matches, isEmpty);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
