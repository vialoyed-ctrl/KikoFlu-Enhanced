import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_progress_action_button.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders mark action and handles taps', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _testApp(
        WorkProgressActionButton(
          onPressed: () => tapCount++,
        ),
      ),
    );

    expect(find.text('Mark'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byType(TextButton));

    expect(tapCount, 1);
  });

  testWidgets('renders selected progress label and icon', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const WorkProgressActionButton(progress: 'listening'),
      ),
    );

    expect(find.text('Listening'), findsOneWidget);
    expect(find.byIcon(Icons.headphones), findsOneWidget);
  });

  testWidgets('renders loading state instead of action', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const WorkProgressActionButton(
          progress: 'listened',
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Listened'), findsNothing);
  });
}
