import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/manual_subtitle_load_flow.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _LoadButton extends StatelessWidget {
  const _LoadButton({
    required this.currentAudioTitle,
    required this.loadSubtitle,
    required this.isMounted,
  });

  final String? currentAudioTitle;
  final ManualSubtitleLoadAction loadSubtitle;
  final ManualSubtitleMountedCheck isMounted;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        runManualSubtitleLoadFlow(
          context,
          file: const {'title': 'track01.srt'},
          workId: 123,
          subtitleTitle: 'track01.srt',
          currentAudioTitle: currentAudioTitle,
          loadSubtitle: loadSubtitle,
          isMounted: isMounted,
        );
      },
      child: const Text('load'),
    );
  }
}

bool _alwaysMounted() => true;

void main() {
  testWidgets('warns and skips loading when no audio is playing',
      (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      _testApp(
        _LoadButton(
          currentAudioTitle: null,
          isMounted: _alwaysMounted,
          loadSubtitle: (_, {required workId}) async {
            loadCount++;
          },
        ),
      ),
    );

    await tester.tap(find.text('load'));
    await tester.pump();

    expect(find.text('No audio playing, cannot load subtitle'), findsOneWidget);
    expect(loadCount, 0);
  });

  testWidgets('cancelling confirmation skips loading', (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      _testApp(
        _LoadButton(
          currentAudioTitle: 'track01.mp3',
          isMounted: _alwaysMounted,
          loadSubtitle: (_, {required workId}) async {
            loadCount++;
          },
        ),
      ),
    );

    await tester.tap(find.text('load'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(loadCount, 0);
  });

  testWidgets('shows loading and success around subtitle load', (tester) async {
    final completer = Completer<void>();
    var receivedWorkId = 0;

    await tester.pumpWidget(
      _testApp(
        _LoadButton(
          currentAudioTitle: 'track01.mp3',
          isMounted: _alwaysMounted,
          loadSubtitle: (_, {required workId}) {
            receivedWorkId = workId;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('load'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Load'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(receivedWorkId, 123);
    expect(find.text('Loading subtitle...'), findsOneWidget);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Subtitle loaded: track01.srt'), findsOneWidget);
  });

  testWidgets('shows failure when subtitle load throws', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _LoadButton(
          currentAudioTitle: 'track01.mp3',
          isMounted: _alwaysMounted,
          loadSubtitle: (_, {required workId}) {
            throw StateError('bad subtitle');
          },
        ),
      ),
    );

    await tester.tap(find.text('load'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Load'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.text('Subtitle load failed: Bad state: bad subtitle'),
      findsOneWidget,
    );
  });
}
