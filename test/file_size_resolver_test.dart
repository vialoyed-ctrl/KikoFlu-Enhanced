import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/file_size_resolver.dart';

void main() {
  group('FileSizeResolver', () {
    test('formats byte counts for metadata display', () {
      expect(FileSizeResolver.formatBytes(null), '');
      expect(FileSizeResolver.formatBytes(0), '');
      expect(FileSizeResolver.formatBytes(512), '512 B');
      expect(FileSizeResolver.formatBytes(1536), '1.50 KB');
      expect(FileSizeResolver.formatBytes(5 * 1024 * 1024), '5.00 MB');
    });

    test('uses positive metadata size before reading local file', () async {
      var readFile = false;
      final resolver = FileSizeResolver(
        downloadRootPath: () async => throw StateError('not needed'),
        fileLength: (_) async {
          readFile = true;
          return 1;
        },
      );

      final size = await resolver.resolveOffline(
        item: {'title': 'track.mp3', 'size': 4096},
        workId: 123,
        parentPath: 'Disc 1',
      );

      expect(size, 4096);
      expect(readFile, isFalse);
    });

    test('reads local file length when metadata size is missing', () async {
      String? requestedPath;
      final resolver = FileSizeResolver(
        downloadRootPath: () async => '/downloads',
        fileLength: (path) async {
          requestedPath = path;
          return 2048;
        },
      );

      final size = await resolver.resolveOffline(
        item: {'title': 'track.mp3'},
        workId: 123,
        parentPath: 'Disc 1',
      );

      expect(size, 2048);
      expect(requestedPath, '/downloads/123/Disc 1/track.mp3');
    });

    test('reads local file length from localRelativePath when present',
        () async {
      String? requestedPath;
      final resolver = FileSizeResolver(
        downloadRootPath: () async => '/downloads',
        fileLength: (path) async {
          requestedPath = path;
          return 1024;
        },
      );

      final size = await resolver.resolveOffline(
        item: const {
          'title': 'track?.mp3',
          'localRelativePath': 'Disc_1/track_.mp3',
        },
        workId: 123,
        parentPath: 'Disc:1',
      );

      expect(size, 1024);
      expect(requestedPath, '/downloads/123/Disc_1/track_.mp3');
    });

    test('reads local file length from an imported RJ work directory',
        () async {
      String? requestedPath;
      final resolver = FileSizeResolver(
        downloadRootPath: () async => '/downloads',
        fileLength: (path) async {
          requestedPath = path;
          return 512;
        },
      );

      final size = await resolver.resolveOffline(
        item: {'title': 'track.mp3'},
        workId: 123456,
        parentPath: 'Disc 1',
        workDirPath: '/downloads/[circle][RJ123456]Title',
      );

      expect(size, 512);
      expect(
        requestedPath,
        '/downloads/[circle][RJ123456]Title/Disc 1/track.mp3',
      );
    });

    test('returns null for missing local file or resolver errors', () async {
      final missingResolver = FileSizeResolver(
        downloadRootPath: () async => '/downloads',
        fileLength: (_) async => null,
      );
      final throwingResolver = FileSizeResolver(
        downloadRootPath: () async => throw StateError('unavailable'),
      );

      expect(
        await missingResolver.resolveOffline(
          item: {'title': 'missing.mp3'},
          workId: 123,
          parentPath: '',
        ),
        isNull,
      );
      expect(
        await throwingResolver.resolveOffline(
          item: {'title': 'missing.mp3'},
          workId: 123,
          parentPath: '',
        ),
        isNull,
      );
    });
  });
}
