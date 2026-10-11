import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/load_subtitle_confirmation_dialog.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
      'LoadSubtitleConfirmationDialog renders selected subtitle and audio',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const LoadSubtitleConfirmationDialog(
          subtitleTitle: 'track01.srt',
          currentAudioTitle: 'track01.mp3',
        ),
      ),
    );

    expect(find.text('track01.srt'), findsOneWidget);
    expect(find.text('track01.mp3'), findsOneWidget);
    expect(find.byIcon(Icons.subtitles), findsOneWidget);
    expect(find.byIcon(Icons.closed_caption), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });
}
