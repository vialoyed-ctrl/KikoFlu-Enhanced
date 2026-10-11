import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kikoeru_flutter/src/services/video_file_opener.dart';

void main() {
  group('VideoFileOpener', () {
    test('opens file URL as local path', () async {
      String? openedPath;
      final opener = VideoFileOpener(
        openLocalFile: (path) async {
          openedPath = path;
          return OpenResult();
        },
      );

      final result = await opener.open('file:///downloads/work/video.mp4');

      expect(result.isSuccess, isTrue);
      expect(openedPath, '/downloads/work/video.mp4');
    });

    test('returns local failure when platform cannot open file', () async {
      final opener = VideoFileOpener(
        openLocalFile: (_) async => OpenResult(
          type: ResultType.noAppToOpen,
          message: 'no app',
        ),
      );

      final result = await opener.openLocalPath('/downloads/video.mp4');

      expect(result.type, VideoOpenResultType.localOpenFailed);
      expect(result.message, 'no app');
      expect(result.path, '/downloads/video.mp4');
    });

    test('returns local error when platform call throws', () async {
      final opener = VideoFileOpener(
        openLocalFile: (_) async => throw StateError('boom'),
      );

      final result = await opener.openLocalPath('/downloads/video.mp4');

      expect(result.type, VideoOpenResultType.localOpenError);
      expect(result.message, contains('boom'));
      expect(result.path, '/downloads/video.mp4');
    });

    test('opens remote URL in external application first', () async {
      final launchedModes = <LaunchMode>[];
      final opener = VideoFileOpener(
        canLaunch: (_) async => true,
        launch: (_, {required mode}) async {
          launchedModes.add(mode);
          return true;
        },
      );

      final result = await opener.open('https://example.test/video.mp4');

      expect(result.isSuccess, isTrue);
      expect(launchedModes, [LaunchMode.externalApplication]);
    });

    test('falls back to non-browser external application', () async {
      final launchedModes = <LaunchMode>[];
      final opener = VideoFileOpener(
        canLaunch: (_) async => true,
        launch: (_, {required mode}) async {
          launchedModes.add(mode);
          return mode == LaunchMode.externalNonBrowserApplication;
        },
      );

      final result = await opener.open('https://example.test/video.mp4');

      expect(result.isSuccess, isTrue);
      expect(launchedModes, [
        LaunchMode.externalApplication,
        LaunchMode.externalNonBrowserApplication,
      ]);
    });

    test('returns remote cannot launch when no handler exists', () async {
      final uri = Uri.parse('https://example.test/video.mp4');
      final opener = VideoFileOpener(
        canLaunch: (_) async => false,
      );

      final result = await opener.openRemoteUri(uri);

      expect(result.type, VideoOpenResultType.remoteCannotLaunch);
      expect(result.uri, uri);
    });

    test('returns remote error when launcher throws', () async {
      final uri = Uri.parse('https://example.test/video.mp4');
      final opener = VideoFileOpener(
        canLaunch: (_) async => true,
        launch: (_, {required mode}) async => throw StateError('launcher down'),
      );

      final result = await opener.openRemoteUri(uri);

      expect(result.type, VideoOpenResultType.remoteOpenError);
      expect(result.message, contains('launcher down'));
      expect(result.uri, uri);
    });

    test('opens browser fallback with platform default mode', () async {
      LaunchMode? launchedMode;
      final uri = Uri.parse('https://example.test/video.mp4');
      final opener = VideoFileOpener(
        launch: (_, {required mode}) async {
          launchedMode = mode;
          return true;
        },
      );

      final launched = await opener.openInBrowser(uri);

      expect(launched, isTrue);
      expect(launchedMode, LaunchMode.platformDefault);
    });
  });
}
