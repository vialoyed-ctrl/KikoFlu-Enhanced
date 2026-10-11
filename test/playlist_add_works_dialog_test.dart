import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/playlist_add_works_dialog.dart';

Widget _testApp({
  required ValueChanged<List<String>> onAddWorks,
}) {
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
                  builder: (context) => PlaylistAddWorksDialog(
                    onAddWorks: onAddWorks,
                  ),
                );
              },
              child: const Text('Open add works'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders empty state with disabled add button', (tester) async {
    await tester.pumpWidget(_testApp(onAddWorks: (_) {}));

    await tester.tap(find.text('Open add works'));
    await tester.pumpAndSettle();

    expect(find.text('Add Works'), findsOneWidget);
    expect(find.text('Work ID'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.textContaining('Detected'), findsNothing);

    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add'),
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets('previews parsed ids and submits them', (tester) async {
    List<String>? submittedIds;
    await tester.pumpWidget(
      _testApp(
        onAddWorks: (ids) {
          submittedIds = ids;
        },
      ),
    );

    await tester.tap(find.text('Open add works'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'RJ123456 rj233333 RJ123456',
    );
    await tester.pumpAndSettle();

    expect(find.text('Detected 2 work IDs'), findsOneWidget);
    expect(find.text('RJ123456'), findsOneWidget);
    expect(find.text('RJ233333'), findsOneWidget);
    expect(find.text('Add 2'), findsOneWidget);

    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();

    expect(submittedIds, ['RJ123456', 'RJ233333']);
    expect(find.text('Add Works'), findsNothing);
  });
}
