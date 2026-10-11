import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/snackbar_util.dart';

Widget _testApp(SnackBar snackBar) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () => SnackBarUtil.showFromSnackBar(
              context,
              snackBar,
            ),
            child: const Text('show'),
          );
        },
      ),
    ),
  );
}

void main() {
  group('SnackBarUtil.showFromSnackBar', () {
    testWidgets('converts red text snackbar to unified error style',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Text('failed'),
            backgroundColor: Colors.red,
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('extracts text from row content', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info),
                Expanded(child: Text('row message')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('row message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('falls back to original snackbar when text cannot be extracted',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SnackBar(
            content: Icon(Icons.circle),
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.byIcon(Icons.circle), findsOneWidget);
    });
  });
}
