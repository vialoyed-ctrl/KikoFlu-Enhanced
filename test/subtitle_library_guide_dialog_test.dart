import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/subtitle_library_guide_dialog.dart';

Widget _testApp() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const SubtitleLibraryGuideDialog(),
                );
              },
              child: const Text('Open guide'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders guide content and closes from action', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Open guide'));
    await tester.pumpAndSettle();

    expect(find.text('Subtitle Library Usage Guide'), findsOneWidget);
    expect(find.text('Subtitle Library Function'), findsOneWidget);
    expect(find.text('Subtitle Auto-load'), findsOneWidget);
    expect(find.text('Smart Categorization & Marking'), findsOneWidget);
    expect(find.textContaining('<Parsed>', findRichText: true), findsWidgets);
    expect(find.byIcon(Icons.closed_caption), findsOneWidget);
    expect(find.byIcon(Icons.audiotrack), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Subtitle Library Usage Guide'), findsNothing);
  });
}
