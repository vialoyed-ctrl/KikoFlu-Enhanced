import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/file_delete_confirmation_dialog.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders delete confirmation content', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const FileDeleteConfirmationDialog(
          relativePath: 'Disc 1/track01.mp3',
        ),
      ),
    );

    expect(find.text('Confirm Delete'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this file?'),
        findsOneWidget);
    expect(find.text('Disc 1/track01.mp3'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('show helper returns false when cancelled and true when deleted',
      (tester) async {
    bool? result;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return Column(
              children: [
                TextButton(
                  onPressed: () async {
                    result = await showFileDeleteConfirmationDialog(
                      context,
                      relativePath: 'Disc 1/track01.mp3',
                    );
                  },
                  child: const Text('open'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
