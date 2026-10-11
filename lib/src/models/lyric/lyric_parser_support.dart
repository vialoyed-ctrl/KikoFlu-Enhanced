import 'lyric_line.dart';

class LyricParserSupport {
  const LyricParserSupport._();

  static List<LyricLine> finalizeLyrics(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<LyricLine> finalLyrics = [];

    for (int i = 0; i < lyrics.length - 1; i++) {
      // 当前字幕的结束时间直接设置为下一行的开始时间
      finalLyrics.add(LyricLine(
        startTime: lyrics[i].startTime,
        endTime: lyrics[i + 1].startTime,
        text: lyrics[i].text,
      ));
    }

    // 最后一行
    final lastIndex = lyrics.length - 1;
    finalLyrics.add(LyricLine(
      startTime: lyrics[lastIndex].startTime,
      endTime: lyrics[lastIndex].endTime == lyrics[lastIndex].startTime
          ? lyrics[lastIndex].startTime + const Duration(seconds: 5)
          : lyrics[lastIndex].endTime,
      text: lyrics[lastIndex].text,
    ));

    return _mergeEmptyLines(finalLyrics);
  }

  static Duration parseTime(int hours, int minutes, double seconds) {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }

  static List<LyricLine> _mergeEmptyLines(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    final List<LyricLine> mergedLyrics = [];

    for (final line in lyrics) {
      final isEmpty = line.text.trim().isEmpty;

      if (mergedLyrics.isEmpty) {
        // 第一行特殊处理：如果是长空行（>=3秒）也替换为音符
        if (isEmpty) {
          mergedLyrics.add(line.copyWith(text: '♪ - ♪'));
        } else {
          mergedLyrics.add(line);
        }
        continue;
      }

      final lastLine = mergedLyrics.last;
      final duration = line.endTime - line.startTime;
      final isShort = duration < const Duration(seconds: 3);

      if (isEmpty && isShort) {
        // 合并到上一行：更新上一行的结束时间
        mergedLyrics.removeLast();
        mergedLyrics.add(lastLine.copyWith(endTime: line.endTime));
      } else {
        // 保留的行：如果是空行（说明是长空行），替换为音符
        if (isEmpty) {
          mergedLyrics.add(line.copyWith(text: '♪ - ♪'));
        } else {
          mergedLyrics.add(line);
        }
      }
    }

    return mergedLyrics;
  }
}
