import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/utils/file_tree_utils.dart';

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
  group('FileTreeUtils', () {
    test('reads map properties and builds item paths', () {
      final item = fileItem('track01.mp3', type: 'audio');

      expect(FileTreeUtils.property(item, 'title'), 'track01.mp3');
      expect(FileTreeUtils.titleOf(item), 'track01.mp3');
      expect(FileTreeUtils.typeOf(item), 'audio');
      expect(FileTreeUtils.itemPath('RJ123456', item), 'RJ123456/track01.mp3');
    });

    test('finds folder children by path', () {
      final tree = [
        folderItem('Disc 1', [
          folderItem('Bonus', [
            fileItem('extra.flac'),
          ]),
        ]),
      ];

      expect(
        FileTreeUtils.findFolderChildren(tree, 'Disc 1/Bonus')
            .map(FileTreeUtils.titleOf),
        ['extra.flac'],
      );
      expect(FileTreeUtils.findFolderChildren(tree, 'Missing'), isEmpty);
    });

    test('counts immediate media and treats library subtitle matches as text',
        () {
      final stats = FileTreeUtils.countImmediateFiles(
        [
          fileItem('track01.flac'),
          fileItem('track02.wav'),
          fileItem('track01.lrc', type: 'text'),
        ],
        audioWithLibrarySubtitles: {'track02.wav'},
      );

      expect(stats.audioCount, 2);
      expect(stats.textCount, 2);
    });

    test('identifies root as main folder when root contains audio', () {
      final result = FileTreeUtils.identifyMainFolder(
        [
          fileItem('track01.mp3'),
          folderItem('Nested', [fileItem('track02.flac')]),
        ],
        AudioFormat.values,
      );

      expect(result?.path, '');
      expect(result?.expandedPaths, isEmpty);
    });

    test('selects folder with most audio then most text', () {
      final tree = [
        folderItem('A', [
          fileItem('a01.mp3'),
          fileItem('a01.lrc', type: 'text'),
        ]),
        folderItem('B', [
          fileItem('b01.mp3'),
          fileItem('b02.mp3'),
        ]),
      ];

      final result = FileTreeUtils.identifyMainFolder(
        tree,
        AudioFormat.values,
      );

      expect(result?.path, 'B');
      expect(result?.audioCount, 2);
      expect(result?.expandedPaths, {'B'});
    });

    test('uses audio format preference as final tie breaker', () {
      final tree = [
        folderItem('MP3', [fileItem('track.mp3')]),
        folderItem('FLAC', [fileItem('track.flac')]),
      ];

      final result = FileTreeUtils.identifyMainFolder(
        tree,
        [AudioFormat.flac, AudioFormat.mp3],
      );

      expect(result?.path, 'FLAC');
    });

    test('collects names, audio files, images, and expanded paths', () {
      final tree = [
        folderItem('Disc 1', [
          fileItem('track01.mp3'),
          fileItem('cover.jpg'),
          folderItem('Nested', [fileItem('scan.png')]),
        ]),
      ];

      expect(FileTreeUtils.expandedPathsFor('Disc 1/Nested'),
          {'Disc 1', 'Disc 1/Nested'});
      expect(
        FileTreeUtils.audioFilesInDirectory(tree, 'Disc 1')
            .map(FileTreeUtils.titleOf),
        ['track01.mp3'],
      );
      expect(
        FileTreeUtils.imageFilesRecursive(tree).map(FileTreeUtils.titleOf),
        ['cover.jpg', 'scan.png'],
      );
      expect(
        FileTreeUtils.collectNames(tree),
        ['Disc 1', 'track01.mp3', 'cover.jpg', 'Nested', 'scan.png'],
      );
    });

    test('finds nested relative path by hash', () {
      final tree = [
        {
          'type': 'folder',
          'title': 'Disc 1',
          'localRelativePath': 'Disc_1',
          'children': [
            folderItem('Scans', [
              fileItem('cover.png', hash: 'img-hash'),
            ]),
            {
              'type': 'audio',
              'title': 'track?.mp3',
              'hash': 'audio-hash',
              'localRelativePath': 'Disc_1/track_.mp3',
            },
          ],
        },
      ];

      expect(
        FileTreeUtils.relativePathForHash(tree, 'img-hash'),
        'Disc_1/Scans/cover.png',
      );
      expect(
        FileTreeUtils.relativePathForHash(tree, 'audio-hash'),
        'Disc_1/track_.mp3',
      );
      expect(FileTreeUtils.relativePathForHash(tree, 'missing'), isNull);
      expect(FileTreeUtils.relativePathForHash(tree, null), isNull);
    });
  });
}
