import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/lyric_provider.dart';

void main() {
  test('manual lyric load reads localPath without server auth', () async {
    final tempDir = await Directory.systemTemp.createTemp('lyric_local_file_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final subtitle = File('${tempDir.path}/track01.lrc');
    await subtitle.writeAsString('[00:01.00]hello');

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(lyricControllerProvider.notifier).loadLyricManually({
      'title': 'track01.lrc',
      'localPath': subtitle.path,
      'hash': 'local:track01.lrc',
    });

    final state = container.read(lyricControllerProvider);
    expect(state.error, isNull);
    expect(state.lyrics, hasLength(1));
    expect(state.lyrics.single.text, 'hello');
    expect(state.lyricUrl, 'file://${subtitle.path}');
  });
}
