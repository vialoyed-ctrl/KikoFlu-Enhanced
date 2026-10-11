import '../lyric_line.dart';
import '../lyric_parser_support.dart';

class SbvLyricParser {
  const SbvLyricParser._();

  static final RegExp timePairPattern = RegExp(
    r'(\d+):(\d{2}):(\d{2})\.(\d{3}),(\d+):(\d{2}):(\d{2})\.(\d{3})',
  );

  static bool matches(String content) {
    return content.contains(RegExp(
      r'^\d+:\d{2}:\d{2}\.\d{3},\d+:\d{2}:\d{2}\.\d{3}',
      multiLine: true,
    ));
  }

  /// 解析 SBV 格式 (YouTube)
  /// 格式:
  /// H:MM:SS.mmm,H:MM:SS.mmm
  /// Text content
  static List<LyricLine> parse(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      final timeMatch = timePairPattern.firstMatch(line);
      if (timeMatch != null) {
        final startTime = Duration(
          hours: int.parse(timeMatch.group(1)!),
          minutes: int.parse(timeMatch.group(2)!),
          seconds: int.parse(timeMatch.group(3)!),
          milliseconds: int.parse(timeMatch.group(4)!),
        );
        final endTime = Duration(
          hours: int.parse(timeMatch.group(5)!),
          minutes: int.parse(timeMatch.group(6)!),
          seconds: int.parse(timeMatch.group(7)!),
          milliseconds: int.parse(timeMatch.group(8)!),
        );

        i++;
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }

        if (textLines.isNotEmpty) {
          lyrics.add(LyricLine(
            startTime: startTime,
            endTime: endTime,
            text: textLines.join('\n'),
          ));
        }
      } else {
        i++;
      }
    }

    return LyricParserSupport.finalizeLyrics(lyrics);
  }
}
