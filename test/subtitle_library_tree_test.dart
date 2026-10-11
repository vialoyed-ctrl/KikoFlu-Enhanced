import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_tree.dart';

Map<String, dynamic> _folder(
  String title,
  String path,
  List<Map<String, dynamic>> children,
) {
  return {
    'type': 'folder',
    'title': title,
    'path': path,
    'children': children,
  };
}

Map<String, dynamic> _file(String title, String path) {
  return {
    'type': 'text',
    'title': title,
    'path': path,
  };
}

void main() {
  group('SubtitleLibraryTree', () {
    test('collects paths recursively', () {
      final tree = [
        _folder('RJ123456', '/root/RJ123456', [
          _file('track.lrc', '/root/RJ123456/track.lrc'),
          _folder('nested', '/root/RJ123456/nested', [
            _file('extra.srt', '/root/RJ123456/nested/extra.srt'),
          ]),
        ]),
      ];

      expect(
        SubtitleLibraryTree.collectPaths(tree),
        {
          '/root/RJ123456',
          '/root/RJ123456/track.lrc',
          '/root/RJ123456/nested',
          '/root/RJ123456/nested/extra.srt',
        },
      );
      expect(
        SubtitleLibraryTree.collectChildPaths(tree.first),
        {
          '/root/RJ123456/track.lrc',
          '/root/RJ123456/nested',
          '/root/RJ123456/nested/extra.srt',
        },
      );
    });

    test('filters matching files while preserving matching folder context', () {
      final tree = [
        _folder('RJ123456', '/root/RJ123456', [
          _file('voice.lrc', '/root/RJ123456/voice.lrc'),
          _file('readme.txt', '/root/RJ123456/readme.txt'),
        ]),
        _folder('Other', '/root/Other', [
          _file('unused.srt', '/root/Other/unused.srt'),
        ]),
      ];

      final result = SubtitleLibraryTree.filterFiles(tree, 'voice');

      expect(result, hasLength(1));
      expect(result.first['title'], 'RJ123456');
      expect(
        (result.first['children'] as List).map((item) => item['title']),
        ['voice.lrc'],
      );
    });

    test('keeps matching folders with filtered children only', () {
      final tree = [
        _folder('RJ123456', '/root/RJ123456', [
          _file('voice.lrc', '/root/RJ123456/voice.lrc'),
        ]),
      ];

      final result = SubtitleLibraryTree.filterFiles(tree, 'RJ123456');

      expect(result, hasLength(1));
      expect(result.first['title'], 'RJ123456');
      expect(result.first['children'], isEmpty);
    });

    test('finds children for current path and falls back to empty', () {
      final nested = _file('extra.srt', '/root/RJ123456/nested/extra.srt');
      final tree = [
        _folder('RJ123456', '/root/RJ123456', [
          _folder('nested', '/root/RJ123456/nested', [nested]),
        ]),
      ];

      expect(
        SubtitleLibraryTree.currentFiles(
          files: tree,
          currentPath: '/root',
          rootPath: '/root',
        ),
        tree,
      );
      expect(
        SubtitleLibraryTree.currentFiles(
          files: tree,
          currentPath: '/root/RJ123456/nested',
          rootPath: '/root',
        ),
        [nested],
      );
      expect(
        SubtitleLibraryTree.currentFiles(
          files: tree,
          currentPath: '/root/missing',
          rootPath: '/root',
        ),
        isEmpty,
      );
    });
  });
}
