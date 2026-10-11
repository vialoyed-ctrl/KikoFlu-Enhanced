import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not interpolate Directory-like objects into filesystem paths', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'''(?:File|Directory)\(\s*['"](?:\$\{[A-Za-z_][A-Za-z0-9_]*(?:Dir|Directory)\}|\$[A-Za-z_][A-Za-z0-9_]*(?:Dir|Directory)\b)''',
    );

    _collectPatternMatches(pattern, offenders);

    expect(
      offenders,
      isEmpty,
      reason: r'Use directory.path or p.join(...), not "$workDir/..." style '
          'interpolation. Interpolating a Directory produces paths like '
          '"Directory: \'/tmp/foo\'/file".',
    );
  });

  test('does not hand-join filesystem paths from .path strings', () {
    final offenders = <String>[];
    final pattern = RegExp(r'''\$\{[^}\n]+\.path\}[/\\]''');

    _collectPatternMatches(pattern, offenders);

    expect(
      offenders,
      isEmpty,
      reason: r'Use p.join(parent.path, child) instead of "${dir.path}/child" '
          'so filesystem paths stay portable across platforms.',
    );
  });
}

void _collectPatternMatches(RegExp pattern, List<String> offenders) {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final source = entity.readAsStringSync();
    for (final match in pattern.allMatches(source)) {
      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      offenders.add('${entity.path}:$line: ${match.group(0)}');
    }
  }
}
