import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/local_work_metadata_service.dart';

void main() {
  group('LocalWorkMetadataService', () {
    test('parses numeric and RJ style work folders', () {
      expect(LocalWorkMetadataService.parseWorkIdFromName('1234'), 1234);
      expect(LocalWorkMetadataService.parseWorkIdFromName('123456'), 123456);
      expect(LocalWorkMetadataService.parseWorkIdFromName('RJ395908'), 395908);
      expect(
        LocalWorkMetadataService.parseWorkIdFromName(
          '[みやぢ屋][RJ334212]ガチ恋不可避',
        ),
        334212,
      );
      expect(LocalWorkMetadataService.parseWorkIdFromName('notes'), isNull);
    });

    test('builds fallback metadata from a local RJ work folder', () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory(
        '${tempDir.path}/[みやぢ屋][RJ334212]ガチ恋不可避',
      );
      await Directory('${workDir.path}/Disc 1').create(recursive: true);
      await File('${workDir.path}/cover.png').writeAsBytes([1, 2, 3]);
      await File('${workDir.path}/Disc 1/track01.mp3').writeAsBytes([1, 2]);
      await File('${workDir.path}/Disc 1/track01.lrc').writeAsString('lyric');
      await File('${workDir.path}/work_metadata.json').writeAsString('{}');
      await File('${workDir.path}/.hidden.mp3').writeAsBytes([0]);

      final service = LocalWorkMetadataService(
        fileLength: (file) async => file.length(),
      );
      final folder = service.parseWorkFolder(workDir);
      final metadata = await service.buildFallbackMetadata(
        workId: folder!.id,
        workDir: workDir,
        directoryName: folder.directoryName,
      );

      expect(folder.id, 334212);
      expect(metadata['id'], 334212);
      expect(metadata['title'], 'ガチ恋不可避');
      expect(metadata['source_id'], 'RJ334212');
      expect(
        metadata['source_url'],
        'https://www.dlsite.com/maniax/work/=/product_id/RJ334212.html',
      );
      expect(metadata['localWorkDirName'], folder.directoryName);
      expect(metadata['localCoverPath'], 'cover.png');

      final children = metadata['children'] as List<dynamic>;
      expect(children, hasLength(1));
      expect(children.single, {
        'type': 'folder',
        'title': 'Disc 1',
        'localRelativePath': 'Disc 1',
        'children': [
          {
            'type': 'text',
            'title': 'track01.lrc',
            'hash': 'local:Disc 1/track01.lrc',
            'localRelativePath': 'Disc 1/track01.lrc',
            'relativePath': 'Disc 1/track01.lrc',
            'size': 5,
          },
          {
            'type': 'audio',
            'title': 'track01.mp3',
            'hash': 'local:Disc 1/track01.mp3',
            'localRelativePath': 'Disc 1/track01.mp3',
            'relativePath': 'Disc 1/track01.mp3',
            'size': 2,
          },
        ],
      });
    });

    test('preserves existing metadata while filling local fields', () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory('${tempDir.path}/RJ395908');
      await workDir.create(recursive: true);
      await File('${workDir.path}/folder.webp').writeAsBytes([1]);
      await File('${workDir.path}/track.wav').writeAsBytes([1, 2, 3]);

      final metadata =
          await const LocalWorkMetadataService().buildFallbackMetadata(
        workId: 395908,
        workDir: workDir,
        directoryName: 'RJ395908',
        existingMetadata: const {
          'title': 'Existing title',
          'source_id': 'custom',
          'source_url': 'https://example.test/work',
        },
      );

      expect(metadata['title'], 'Existing title');
      expect(metadata['source_id'], 'custom');
      expect(metadata['source_url'], 'https://example.test/work');
      expect(metadata['localWorkDirName'], 'RJ395908');
      expect(metadata['localCoverPath'], 'folder.webp');
      expect(metadata['children'], [
        {
          'type': 'audio',
          'title': 'track.wav',
          'hash': 'local:track.wav',
          'localRelativePath': 'track.wav',
          'relativePath': 'track.wav',
          'size': 3,
        },
      ]);
    });

    test('detects nested local cover when root has no cover candidate',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory('${tempDir.path}/RJ123456');
      await workDir.create(recursive: true);
      await File('${workDir.path}/Scans/folder.png').create(recursive: true);
      await File('${workDir.path}/Scans/cover.webp').writeAsBytes([1]);
      await File('${workDir.path}/Disc 1/track.mp3').create(recursive: true);

      final metadata =
          await const LocalWorkMetadataService().buildFallbackMetadata(
        workId: 123456,
        workDir: workDir,
        directoryName: 'RJ123456',
      );

      expect(metadata['localCoverPath'], 'Scans/cover.webp');

      final children = metadata['children'] as List<dynamic>;
      final scanFolder = children.cast<Map<String, dynamic>>().singleWhere(
            (item) => item['title'] == 'Scans',
          );
      final scanTitles = (scanFolder['children'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => item['title']);

      expect(scanTitles, ['cover.webp', 'folder.png']);
    });

    test('uses imported metadata aliases before directory fallback', () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory('${tempDir.path}/RJ765432');
      await workDir.create(recursive: true);
      await File('${workDir.path}/metadata.json').writeAsString('''
{
  "work": {
    "work_name": "Imported title",
    "product_id": "rj765432",
    "product_url": "https://example.test/RJ765432",
    "circle": {"name": "Imported circle"},
    "release_date": "2024-05-06"
  }
}
''');
      await File('${workDir.path}/track.mp3').writeAsBytes([1, 2, 3]);

      const service = LocalWorkMetadataService();
      final imported = await service.loadImportedMetadata(
        workDir: workDir,
        workId: 765432,
      );
      final metadata = await service.buildFallbackMetadata(
        workId: 765432,
        workDir: workDir,
        directoryName: 'RJ765432',
        existingMetadata: imported,
      );

      expect(metadata['title'], 'Imported title');
      expect(metadata['source_id'], 'RJ765432');
      expect(metadata['source_url'], 'https://example.test/RJ765432');
      expect(metadata['name'], 'Imported circle');
      expect(metadata['release'], '2024-05-06');

      final children = metadata['children'] as List<dynamic>;
      expect(children, hasLength(1));
      expect((children.single as Map<String, dynamic>)['title'], 'track.mp3');
    });

    test('forces imported metadata id to the parsed work id', () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory('${tempDir.path}/RJ222222');
      await workDir.create(recursive: true);
      await File('${workDir.path}/metadata.json').writeAsString('''
{
  "id": 999999,
  "title": "Imported title"
}
''');
      await File('${workDir.path}/track.mp3').writeAsBytes([1]);

      const service = LocalWorkMetadataService();
      final imported = await service.loadImportedMetadata(
        workDir: workDir,
        workId: 222222,
      );
      final metadata = await service.buildFallbackMetadata(
        workId: 222222,
        workDir: workDir,
        directoryName: 'RJ222222',
        existingMetadata: imported,
      );

      expect(metadata['id'], 222222);
      expect(metadata['title'], 'Imported title');
    });

    test('keeps nested generic json files in the imported file tree', () async {
      final tempDir = await Directory.systemTemp.createTemp('kikoflu_local_');
      addTearDown(() => tempDir.delete(recursive: true));

      final workDir = Directory('${tempDir.path}/RJ111111');
      await workDir.create(recursive: true);
      await File('${workDir.path}/metadata.json')
          .writeAsString('{"title":"Root metadata"}');
      await File('${workDir.path}/Docs/info.json').create(recursive: true);

      final metadata =
          await const LocalWorkMetadataService().buildFallbackMetadata(
        workId: 111111,
        workDir: workDir,
        directoryName: 'RJ111111',
      );

      final children = metadata['children'] as List<dynamic>;
      final docsFolder = children.cast<Map<String, dynamic>>().singleWhere(
            (item) => item['title'] == 'Docs',
          );
      expect(
        (docsFolder['children'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((item) => item['title']),
        ['info.json'],
      );
    });
  });
}
