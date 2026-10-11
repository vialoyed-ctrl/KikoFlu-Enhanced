import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/subtitle_library_content_view.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders loading before all other states', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const SubtitleLibraryContentView(
          isLoading: true,
          empty: true,
          errorMessage: 'Failed',
          child: Text('content'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Failed'), findsNothing);
    expect(find.text('Subtitle library is empty'), findsNothing);
    expect(find.text('content'), findsNothing);
  });

  testWidgets('renders error and retry action', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      _testApp(
        SubtitleLibraryContentView(
          isLoading: false,
          empty: false,
          errorMessage: 'Failed to load',
          onRetry: () => retryCount++,
          child: const Text('content'),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));

    expect(retryCount, 1);
  });

  testWidgets('renders empty state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const SubtitleLibraryContentView(
          isLoading: false,
          empty: true,
          child: Text('content'),
        ),
      ),
    );

    expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);
    expect(find.text('Subtitle library is empty'), findsOneWidget);
    expect(find.text('Tap the + button to import subtitles'), findsOneWidget);
    expect(find.text('content'), findsNothing);
  });

  testWidgets('renders content when ready', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const SubtitleLibraryContentView(
          isLoading: false,
          empty: false,
          child: Text('content'),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.byIcon(Icons.library_books_outlined), findsNothing);
  });
}
