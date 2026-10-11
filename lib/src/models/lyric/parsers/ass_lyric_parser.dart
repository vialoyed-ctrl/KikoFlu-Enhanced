import '../lyric_line.dart';
import '../lyric_parser_support.dart';

class AssLyricParser {
  const AssLyricParser._();

  // ASS 时间格式: H:MM:SS.cc (centiseconds)
  static final RegExp timePattern = RegExp(r'(\d+):(\d{2}):(\d{2})\.(\d{2})');

  static bool matches(String content) {
    return content.contains('[Events]') &&
        content.contains(RegExp(r'^Dialogue:', multiLine: true));
  }

  /// 解析 ASS/SSA 格式
  /// 格式: Dialogue: Layer,H:MM:SS.cc,H:MM:SS.cc,Style,Name,MarginL,MarginR,MarginV,Effect,Text
  static List<LyricLine> parse(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('Dialogue:')) continue;

      // 找到 Dialogue: 后面的内容，按逗号分割（前9个逗号是字段分隔，第10个字段是文本）
      final afterDialogue = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      final parts = afterDialogue.split(',');
      if (parts.length < 10) continue;

      final startMatch = timePattern.firstMatch(parts[1].trim());
      final endMatch = timePattern.firstMatch(parts[2].trim());
      if (startMatch == null || endMatch == null) continue;

      final startTime = _parseTime(startMatch);
      final endTime = _parseTime(endMatch);

      // 文本是第10个字段之后的所有内容（文本中可能含逗号）
      var text = parts.sublist(9).join(',');

      // 处理 ASS 特殊标记
      text = text
          .replaceAll(RegExp(r'\{[^}]*\}'), '') // 移除 {\\b1} 等内联样式
          .replaceAll('\\N', '\n') // 换行符
          .replaceAll('\\n', '\n') // 软换行
          .replaceAll('\\h', ' ') // 硬空格
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

  /// 解析 ASS 时间: H:MM:SS.cc → Duration
  static Duration _parseTime(RegExpMatch match) {
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
  }
}
