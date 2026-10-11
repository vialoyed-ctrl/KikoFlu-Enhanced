import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/video_open_failure_dialog.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('local dialog renders failure reason and file path',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const VideoOpenFailureDialog.local(
          errorMessage: 'no app',
          filePath: '/downloads/work/video.mp4',
        ),
      ),
    );

    expect(find.text('Cannot open video'), findsOneWidget);
    expect(find.text('Error: no app'), findsOneWidget);
    expect(find.text('/downloads/work/video.mp4'), findsOneWidget);
  });

  testWidgets('remote dialog exposes URL and browser fallback', (tester) async {
    var openedInBrowser = false;

    await tester.pumpWidget(
      _testApp(
        VideoOpenFailureDialog.remote(
          videoUrl: 'https://example.test/video.mp4',
          onOpenInBrowser: () async {
            openedInBrowser = true;
          },
        ),
      ),
    );

    expect(find.text('Cannot play directly'), findsOneWidget);
    expect(find.text('https://example.test/video.mp4'), findsOneWidget);

    await tester.tap(find.text('2. Open in browser').last);
    await tester.pumpAndSettle();

    expect(openedInBrowser, isTrue);
  });
}
