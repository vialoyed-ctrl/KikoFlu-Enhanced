import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/translation_toggle_button.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_title_header.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
    description: 'RichText containing "$text"',
  );
}

void main() {
  testWidgets('renders original title and triggers translate action',
      (tester) async {
    var translateCount = 0;

    await tester.pumpWidget(
      _host(
        WorkTitleHeader(
          title: 'Original Title',
          showTranslateButton: true,
          onTranslate: () => translateCount++,
        ),
      ),
    );

    expect(_richTextContaining('Original Title'), findsOneWidget);
    expect(find.byType(InlineTranslationButton), findsOneWidget);

    await tester.tap(find.byType(InlineTranslationButton));

    expect(translateCount, 1);
  });

  testWidgets('renders translated title and copies visible title',
      (tester) async {
    String? copiedTitle;

    await tester.pumpWidget(
      _host(
        WorkTitleHeader(
          title: 'Original Title',
          translatedTitle: 'Translated Title',
          showTranslation: true,
          onCopy: (title) => copiedTitle = title,
        ),
      ),
    );

    expect(_richTextContaining('Translated Title'), findsOneWidget);
    expect(_richTextContaining('Original Title'), findsNothing);

    await tester.longPress(_richTextContaining('Translated Title'));

    expect(copiedTitle, 'Translated Title');
  });

  testWidgets('renders external link action when enabled', (tester) async {
    var openCount = 0;

    await tester.pumpWidget(
      _host(
        WorkTitleHeader(
          title: 'Original Title',
          showExternalLink: true,
          onOpenExternalLink: () => openCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.open_in_new), findsOneWidget);

    await tester.tap(find.byIcon(Icons.open_in_new));

    expect(openCount, 1);
  });

  testWidgets('can hide translate button', (tester) async {
    await tester.pumpWidget(
      _host(
        const WorkTitleHeader(
          title: 'Original Title',
          showTranslateButton: false,
        ),
      ),
    );

    expect(_richTextContaining('Original Title'), findsOneWidget);
    expect(find.byType(InlineTranslationButton), findsNothing);
  });
}
