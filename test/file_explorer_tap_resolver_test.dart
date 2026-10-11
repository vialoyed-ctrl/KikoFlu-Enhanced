import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/file_explorer_tap_resolver.dart';

Map<String, dynamic> fileItem(String title, {String? type}) {
  return {
    'title': title,
    if (type != null) 'type': type,
  };
}

void main() {
  test('resolves common preview and playback actions', () {
    const resolver = FileExplorerTapResolver();

    expect(
      resolver.resolve(fileItem('track.mp3')),
      FileExplorerTapAction.audio,
    );
    expect(
      resolver.resolve(fileItem('movie.mp4')),
      FileExplorerTapAction.video,
    );
    expect(
      resolver.resolve(fileItem('cover.webp')),
      FileExplorerTapAction.image,
    );
    expect(
      resolver.resolve(fileItem('booklet.pdf')),
      FileExplorerTapAction.pdf,
    );
    expect(
      resolver.resolve(fileItem('readme.txt')),
      FileExplorerTapAction.text,
    );
    expect(
      resolver.resolve(fileItem('archive.zip')),
      FileExplorerTapAction.unsupported,
    );
  });

  test('honors media priority for ambiguous files', () {
    final ambiguousFile = fileItem('clip.mp4', type: 'audio');

    expect(
      const FileExplorerTapResolver(videoBeforeAudio: true)
          .resolve(ambiguousFile),
      FileExplorerTapAction.video,
    );
    expect(
      const FileExplorerTapResolver(videoBeforeAudio: false)
          .resolve(ambiguousFile),
      FileExplorerTapAction.audio,
    );
  });
}
