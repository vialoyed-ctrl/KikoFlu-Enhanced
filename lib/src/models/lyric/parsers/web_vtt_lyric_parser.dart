import '../lyric_line.dart';
import '../lyric_parser_support.dart';

class WebVttLyricParser {
  const WebVttLyricParser._();

  static final RegExp cueTimePattern = RegExp(
    r'(?:(\d{2}):)?(\d{2}):(\d{2}[.,]\d{3})\s*-->\s*(?:(\d{2}):)?(\d{2}):(\d{2}[.,]\d{3})',
  );

  static List<LyricLine> parse(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.isEmpty || line.startsWith('WEBVTT') || line == 'NOTE') {
        i++;
        continue;
      }

      final timeMatch = cueTimePattern.firstMatch(line);

      if (timeMatch != null) {
        final startTime = LyricParserSupport.parseTime(
          int.parse(timeMatch.group(1) ?? '0'),
          int.parse(timeMatch.group(2)!),
          double.parse(timeMatch.group(3)!.replaceAll(',', '.')),
        );

        final endTime = LyricParserSupport.parseTime(
          int.parse(timeMatch.group(4) ?? '0'),
          int.parse(timeMatch.group(5)!),
          double.parse(timeMatch.group(6)!.replaceAll(',', '.')),
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
