import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/file_explorer_header.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('FileExplorerHeader renders title and trailing action',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _testApp(
        FileExplorerHeader(
          title: 'Resource Files',
          trailing: IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text('Resource Files'), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);

    await tester.tap(find.byIcon(Icons.translate));

    expect(tapCount, 1);
  });

  testWidgets('FileExplorerProgressBanner renders spinner and message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const FileExplorerProgressBanner(
          message: 'Translating 2/4',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Translating 2/4'), findsOneWidget);
  });
}
