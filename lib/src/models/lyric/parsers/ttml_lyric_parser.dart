import '../lyric_line.dart';
import '../lyric_parser_support.dart';

class TtmlLyricParser {
  const TtmlLyricParser._();

  // 匹配 <p begin="..." end="...">...</p>（支持跨行）
  static final RegExp paragraphPattern = RegExp(
    r'<p\s+begin="([^"]+)"\s+end="([^"]+)"[^>]*>(.*?)</p>',
    dotAll: true,
  );

  // TTML 时间格式: HH:MM:SS.mmm 或 HH:MM:SS:ff
  static final RegExp timePattern =
      RegExp(r'(\d{2}):(\d{2}):(\d{2})[.:](\d{3})');

  static bool matches(String content) {
    return content.contains(RegExp(r'<p\s+begin='));
  }

  /// 解析 TTML/DFXP 格式 (XML)
  /// 格式: <p begin="HH:MM:SS.mmm" end="HH:MM:SS.mmm">Text</p>
  static List<LyricLine> parse(String content) {
    final List<LyricLine> lyrics = [];

    for (final match in paragraphPattern.allMatches(content)) {
      final beginStr = match.group(1)!;
      final endStr = match.group(2)!;
      var text = match.group(3)!;

      final startMatch = timePattern.firstMatch(beginStr);
      final endMatch = timePattern.firstMatch(endStr);
      if (startMatch == null || endMatch == null) continue;

      final startTime = Duration(
        hours: int.parse(startMatch.group(1)!),
        minutes: int.parse(startMatch.group(2)!),
        seconds: int.parse(startMatch.group(3)!),
        milliseconds: int.parse(startMatch.group(4)!),
      );
      final endTime = Duration(
        hours: int.parse(endMatch.group(1)!),
        minutes: int.parse(endMatch.group(2)!),
        seconds: int.parse(endMatch.group(3)!),
        milliseconds: int.parse(endMatch.group(4)!),
      );

      // 移除 XML/HTML 标签，保留文本
      text = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .trim();

      if (text.isEmpty) continue;

      lyrics.add(LyricLine(
        startTime: startTime,
        endTime: endTime,
        text: text,
      ));
    }

    return LyricParserSupport.finalizeLyrics(lyrics);
  }
}
