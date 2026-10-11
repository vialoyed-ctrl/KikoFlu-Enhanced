import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/downloaded_file_state_scanner.dart';

Map<String, dynamic> fileItem(
  String title, {
  String? type,
  String? hash,
}) {
  return {
    'type': type ?? 'file',
    'title': title,
    if (hash != null) 'hash': hash,
  };
}

Map<String, dynamic> folderItem(
  String title,
  List<dynamic> children,
) {
  return {
    'type': 'folder',
    'title': title,
    'children': children,
  };
}

void main() {
  group('DownloadedFileStateScanner', () {
    test('collects relative paths and marks completed downloads', () async {
      final scanner = DownloadedFileStateScanner(
        resolveDownloadedPath: (workId, hash) async =>
            hash == 'downloaded' ? '/downloads/$workId/track01.mp3' : null,
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );

      final result = await scanner.scan(
        workId: 123,
        fileTree: [
          folderItem('Disc 1', [
            fileItem('track01.mp3', type: 'audio', hash: 'downloaded'),
            fileItem('track02.mp3', type: 'audio', hash: 'missing'),
          ]),
        ],
      );

      expect(result.fileRelativePaths, {
        'downloaded': 'Disc 1/track01.mp3',
        'missing': 'Disc 1/track02.mp3',
      });
      expect(result.downloadedFiles, {
        'downloaded': true,
        'missing': false,
      });
    });

    test('marks manually copied files by relative path', () async {
      final scanner = DownloadedFileStateScanner(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/Disc 1/book.pdf',
      );

      final result = await scanner.scan(
        workId: 123,
        fileTree: [
          folderItem('Disc 1', [
            fileItem('book.pdf', type: 'pdf', hash: 'pdf'),
            fileItem('cover.jpg', type: 'image', hash: 'image'),
          ]),
        ],
      );

      expect(result.downloadedFiles['pdf'], isTrue);
      expect(result.downloadedFiles['image'], isFalse);
    });

    test('uses localRelativePath when metadata points to sanitized file names',
        () async {
      final scanner = DownloadedFileStateScanner(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/Disc_1/track_.mp3',
      );

      final result = await scanner.scan(
        workId: 123,
        fileTree: [
          folderItem('Disc:1', [
            {
              'type': 'audio',
              'title': 'track?.mp3',
              'hash': 'audio',
              'localRelativePath': 'Disc_1/track_.mp3',
            },
          ]),
        ],
      );

      expect(result.fileRelativePaths['audio'], 'Disc_1/track_.mp3');
      expect(result.downloadedFiles['audio'], isTrue);
    });

    test('inherits folder localRelativePath for child file paths', () async {
      final scanner = DownloadedFileStateScanner(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/Disc_1/track01.mp3',
      );

      final result = await scanner.scan(
        workId: 123,
        fileTree: [
          {
            'type': 'folder',
            'title': 'Disc:1',
            'localRelativePath': 'Disc_1',
            'children': [
              fileItem('track01.mp3', type: 'audio', hash: 'audio'),
            ],
          },
        ],
      );

      expect(result.fileRelativePaths['audio'], 'Disc_1/track01.mp3');
      expect(result.downloadedFiles['audio'], isTrue);
    });

    test('ignores folders and hashless files', () async {
      final scanner = DownloadedFileStateScanner(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );

      final result = await scanner.scan(
        workId: 123,
        fileTree: [
          fileItem('readme.txt'),
          folderItem('Empty', []),
        ],
      );

      expect(result.downloadedFiles, isEmpty);
      expect(result.fileRelativePaths, isEmpty);
    });
  });
}
