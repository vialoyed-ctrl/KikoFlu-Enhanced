import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/services/audio_playback_plan_builder.dart';

void main() {
  test(
    'online video enters mixed media queue and keeps subtitle work metadata',
    () async {
      final video = {'type': 'video', 'title': 'clip.mp4', 'hash': 'video'};
      final plan = await const AudioPlaybackPlanBuilder().build(
        fileTree: [
          {'type': 'audio', 'title': 'song.wav', 'hash': 'audio'},
          video,
          {'type': 'text', 'title': 'clip.srt', 'hash': 'subtitle'},
        ],
        includeVideo: true,
        parentPath: '',
        selectedFile: video,
        resolveUrl: (file) async => 'https://host/stream/${file['hash']}',
        work: const Work(id: 42, title: 'Demo'),
        unknownTitle: 'Unknown',
      );
      expect(plan.status, AudioPlaybackPlanStatus.ready);
      expect(plan.queue!.tracks.length, 2);
      expect(plan.queue!.startIndex, 1);
      expect(plan.queue!.tracks.last.isVideo, isTrue);
      expect(plan.queue!.tracks.last.workId, 42);
    },
  );
  test('local video keeps source path and local subtitle directory', () async {
    final video = {'type': 'video', 'title': 'clip.webm', 'hash': 'video'};
    final plan = await const AudioPlaybackPlanBuilder().build(
      fileTree: [video],
      includeVideo: true,
      parentPath: '',
      selectedFile: video,
      resolveUrl: (_) async => 'file:///downloads/clip.webm',
      work: const Work(id: 42, title: 'Demo'),
      unknownTitle: 'Unknown',
      subtitleWorkDirPath: '/downloads',
    );
    expect(plan.status, AudioPlaybackPlanStatus.ready);
    expect(plan.queue!.tracks.single.sourcePath, '/downloads/clip.webm');
    expect(plan.queue!.tracks.single.subtitleWorkDirPath, '/downloads');
  });
}
