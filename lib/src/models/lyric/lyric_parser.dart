import 'lyric_line.dart';
import 'parsers/ass_lyric_parser.dart';
import 'parsers/lrc_lyric_parser.dart';
import 'parsers/sbv_lyric_parser.dart';
import 'parsers/ttml_lyric_parser.dart';
import 'parsers/web_vtt_lyric_parser.dart';

class LyricParser {
  static List<LyricLine> parse(String content) {
    List<LyricLine> result = [];

    if (LrcLyricParser.matches(content)) {
      result = parseLRC(content);
    } else if (AssLyricParser.matches(content)) {
      result = parseASS(content);
    } else if (TtmlLyricParser.matches(content)) {
      result = parseTTML(content);
    } else if (SbvLyricParser.matches(content)) {
      result = parseSBV(content);
    } else {
      result = parseWebVTT(content);
    }

    if (result.isEmpty) {
      throw const FormatException("解析失败，格式不支持");
    }

    return result;
  }

  static List<LyricLine> parseLRC(String content) {
    return LrcLyricParser.parse(content);
  }

  static List<LyricLine> parseWebVTT(String content) {
    return WebVttLyricParser.parse(content);
  }

  static List<LyricLine> parseASS(String content) {
    return AssLyricParser.parse(content);
  }

  static List<LyricLine> parseSBV(String content) {
    return SbvLyricParser.parse(content);
  }

  static List<LyricLine> parseTTML(String content) {
    return TtmlLyricParser.parse(content);
  }

  static String? getCurrentLyric(List<LyricLine> lyrics, Duration position) {
    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];
      if (position >= lyric.startTime && position < lyric.endTime) {
        return lyric.text;
      }
      if (i < lyrics.length - 1) {
        final nextLyric = lyrics[i + 1];
        if (position >= lyric.endTime && position < nextLyric.startTime) {
          final gap = nextLyric.startTime - lyric.endTime;
          return gap < const Duration(seconds: 1) ? lyric.text : null;
        }
      }
    }
    return null;
  }
}
