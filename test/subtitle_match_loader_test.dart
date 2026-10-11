import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/subtitle_match_loader.dart';

void main() {
  test('loads subtitle matches through injected directory and finder',
      () async {
    final libraryDir = Directory('/tmp/subtitles');
    final fileTree = [
      {'type': 'audio', 'title': 'track01.mp3'},
    ];
    Directory? receivedDir;
    int? receivedWorkId;
    List<dynamic>? receivedTree;

    final loader = SubtitleMatchLoader(
      libraryDirectoryProvider: () async => libraryDir,
      findMatches: ({
        required libraryDir,
        required workId,
        required fileTree,
      }) async {
        receivedDir = libraryDir;
        receivedWorkId = workId;
        receivedTree = fileTree;
        return {'track01.mp3'};
      },
    );

    final matches = await loader.loadMatches(
      workId: 123,
      fileTree: fileTree,
    );

    expect(matches, {'track01.mp3'});
    expect(receivedDir, libraryDir);
    expect(receivedWorkId, 123);
    expect(receivedTree, same(fileTree));
  });
}
