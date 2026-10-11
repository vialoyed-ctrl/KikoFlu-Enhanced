import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/local_file_url.dart';

void main() {
  group('LocalFileUrl', () {
    test('keeps raw local paths that are not percent encoded', () {
      expect(
        LocalFileUrl.pathFromUrl('file:///downloads/100% pure.mp3'),
        '/downloads/100% pure.mp3',
      );
    });

    test('decodes standard percent-encoded file URLs', () {
      expect(
        LocalFileUrl.pathFromUrl(
          'file:///downloads/100%25%20pure/%E5%8F%B3%E8%80%B3.mp3',
        ),
        '/downloads/100% pure/右耳.mp3',
      );
    });

    test('does not parse local file URLs through Uri semantics', () {
      expect(
        LocalFileUrl.pathFromUrl('file:///downloads/a#b?c.mp3'),
        '/downloads/a#b?c.mp3',
      );
    });

    test('normalizes leading slash before Windows drive letters on Windows',
        () {
      expect(
        LocalFileUrl.pathFromUrl(
          'file:///C:/Users/me/Music/track.mp3',
          isWindows: true,
        ),
        'C:/Users/me/Music/track.mp3',
      );
    });

    test('returns null for non-local URLs', () {
      expect(
        LocalFileUrl.pathFromUrl('https://example.test/track.mp3'),
        isNull,
      );
    });
  });
}
