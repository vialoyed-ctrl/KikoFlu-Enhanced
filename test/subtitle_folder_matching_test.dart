import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/subtitle_folder_matching.dart';

void main() {
  test(
    'duplicate sequence resolves only an exact title within that sequence',
    () {
      expect(
        SubtitleFolderMatcher.select('02 Main.wav', [
          'a/02 Main.lrc',
          'b/02 Extra.lrc',
        ]),
        'a/02 Main.lrc',
      );
    },
  );
  test('RJ identity preserves all nonzero digits', () {
    expect(SubtitleFolderMatcher.workNumber('RJ0213146'), 213146);
    expect(SubtitleFolderMatcher.workNumber('RJ5213146'), 5213146);
    expect(SubtitleFolderMatcher.workNumber('RJ350815'), 350815);
    expect(SubtitleFolderMatcher.workNumber('other 213146'), isNull);
  });
  test('track numbers survive different titles and full width digits', () {
    expect(SubtitleFolderMatcher.sequence('Track02 audio.wav'), 2);
    expect(SubtitleFolderMatcher.sequence('０２. caption.lrc'), 2);
    expect(SubtitleFolderMatcher.sequence('第3章.wav'), 3);
    expect(SubtitleFolderMatcher.sequence('RJ350815 cover.wav'), isNull);
    expect(SubtitleFolderMatcher.sequence('unrelated 2026.wav'), isNull);
  });
  test('RJ350815 numbered audio resolves corresponding LRC not ASS', () {
    final files = [
      'set/01_caption.lrc',
      'set/02_caption.ass',
      'set/02_caption.lrc',
    ];
    expect(
      SubtitleFolderMatcher.select('Track02 audio.wav', files),
      'set/02_caption.lrc',
    );
    expect(SubtitleFolderMatcher.select('Track03 audio.wav', files), isNull);
  });
  test('ambiguous numbered versions require manual selection', () {
    expect(
      SubtitleFolderMatcher.select('02.wav', ['a/02.lrc', 'b/02.lrc']),
      isNull,
    );
    expect(
      SubtitleFolderMatcher.select('02.wav', ['a/02.lrc', 'a/02.vtt']),
      'a/02.lrc',
    );
  });
}
