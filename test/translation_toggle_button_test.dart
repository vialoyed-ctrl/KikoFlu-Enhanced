import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/translation_toggle_button.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('shows translated label and handles taps', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        TranslationToggleButton(
          isTranslated: false,
          originalLabel: 'Original',
          translatedLabel: 'Translate',
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.byIcon(Icons.g_translate), findsOneWidget);

    await tester.tap(find.byType(TranslationToggleButton));

    expect(tapCount, 1);
  });

  testWidgets('shows original label when translated', (tester) async {
    await tester.pumpWidget(
      _host(
        const TranslationToggleButton(
          isTranslated: true,
          originalLabel: 'Original',
          translatedLabel: 'Translate',
          onPressed: null,
        ),
      ),
    );

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Translate'), findsNothing);
  });

  testWidgets('loading state disables taps and shows progress', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        TranslationToggleButton(
          isTranslated: false,
          isLoading: true,
          originalLabel: 'Original',
          translatedLabel: 'Translate',
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Translate'), findsNothing);

    await tester.tap(find.byType(TranslationToggleButton));

    expect(tapCount, 0);
  });

  testWidgets('InlineTranslationButton renders compact icon and handles taps',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        InlineTranslationButton(
          isTranslated: false,
          isLoading: false,
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.g_translate), findsOneWidget);

    await tester.tap(find.byType(InlineTranslationButton));

    expect(tapCount, 1);
  });

  testWidgets('InlineTranslationButton loading state disables taps',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        InlineTranslationButton(
          isTranslated: true,
          isLoading: true,
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(InlineTranslationButton));

    expect(tapCount, 0);
  });

  testWidgets('TranslationToolbarButton keeps toolbar tap behavior',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        TranslationToolbarButton(
          isTranslated: false,
          isLoading: false,
          tooltip: 'Translate content',
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.g_translate), findsOneWidget);
    expect(find.byTooltip('Translate content'), findsOneWidget);

    await tester.tap(find.byType(TranslationToolbarButton));

    expect(tapCount, 1);
  });

  testWidgets('TranslationToolbarButton loading state disables taps',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _host(
        TranslationToolbarButton(
          isTranslated: true,
          isLoading: true,
          tooltip: 'Show original',
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(TranslationToolbarButton));

    expect(tapCount, 0);
  });
}
