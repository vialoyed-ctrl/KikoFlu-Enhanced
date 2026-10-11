import 'package:path/path.dart' as p;
import 'subtitle_matching.dart';

class SubtitleFolderMatcher {
  static String fold(String value) => String.fromCharCodes(
    value.runes.map(
      (c) => c == 0x3000
          ? 32
          : c >= 0xff01 && c <= 0xff5e
          ? c - 0xfee0
          : c,
    ),
  );

  static int? workNumber(String value) {
    final match = RegExp(
      r'(?<![a-z0-9])RJ(\d+)(?!\d)',
      caseSensitive: false,
    ).firstMatch(fold(value));
    return match == null ? null : int.tryParse(match[1]!);
  }

  static int? sequence(String value) {
    final name = fold(p.basename(value.replaceAll('\\', '/'))).trim();
    final match = RegExp(
      r'^(?:[\[({【「\s]*)(?:(?:track|tr|chapter|ch|part|vol|第)\s*[._\- ]*)?(\d{1,3})(?!\d)',
      caseSensitive: false,
    ).firstMatch(name);
    return match == null ? null : int.tryParse(match[1]!);
  }

  static bool supported(String file) => [
    '.lrc',
    '.vtt',
    '.srt',
    '.txt',
  ].contains(p.extension(file).toLowerCase());

  static String? select(String audio, List<String> files) {
    final usable = files.where(supported).toList();
    final number = sequence(audio);
    if (number != null) {
      final numbered = usable.where((f) => sequence(f) == number).toList();
      if (numbered.isNotEmpty) {
        final unique = _uniqueVersion(numbered);
        if (unique != null) return unique;
        final exact = numbered
            .where(
              (f) => SubtitleMatcher.check(p.basename(f), audio).score == 1,
            )
            .toList();
        return exact.isEmpty ? null : _uniqueVersion(exact);
      }
      return null;
    }
    final exact = usable
        .where((f) => SubtitleMatcher.check(p.basename(f), audio).score == 1)
        .toList();
    return exact.isEmpty ? null : _uniqueVersion(exact);
  }

  static String? _uniqueVersion(List<String> files) {
    final stems = files.map((f) => p.withoutExtension(f)).toSet();
    if (stems.length != 1) return null;
    files.sort(
      (a, b) => ['.lrc', '.vtt', '.srt', '.txt']
          .indexOf(p.extension(a).toLowerCase())
          .compareTo(
            [
              '.lrc',
              '.vtt',
              '.srt',
              '.txt',
            ].indexOf(p.extension(b).toLowerCase()),
          ),
    );
    return files.first;
  }
}
