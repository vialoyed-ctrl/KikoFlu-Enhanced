import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/providers/lyric_provider.dart';

void main() {
  test('manual subtitles belong to current track and use timeline offset', () async {
    final folder = await Directory.systemTemp.createTemp('navigation_cues_');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/test.lrc');
    await file.writeAsString('[00:01.00]first\n[00:12.00]second');
    const track = AudioTrack(id: 'one', title: 'one', url: 'file:///one.wav');
    const other = AudioTrack(id: 'two', title: 'two', url: 'file:///two.wav');
    final container = ProviderContainer(overrides: [
      currentTrackProvider.overrideWith((ref) => Stream.value(track)),
    ]);
    addTearDown(container.dispose);
    await container.read(currentTrackProvider.future);
    final controller = container.read(lyricControllerProvider.notifier);
    await controller.loadLyricManually({'title': 'test.lrc', 'localPath': file.path});
    controller.adjustTimelineOffset(const Duration(seconds: 3));
    expect(controller.navigationStartsFor(track), [
      const Duration(seconds: 4), const Duration(seconds: 15)]);
    expect(controller.navigationStartsFor(other), isEmpty);
    controller.clearLyrics();
    expect(controller.navigationStartsFor(track), isEmpty);
  });
}
