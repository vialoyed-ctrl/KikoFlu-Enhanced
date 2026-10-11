import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_detail_error_banner.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('hides when message is empty', (tester) async {
    await tester.pumpWidget(
      _testApp(const WorkDetailErrorBanner()),
    );

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('renders message and retry action', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      _testApp(
        WorkDetailErrorBanner(
          message: 'Failed to load details',
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Failed to load details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));

    expect(retryCount, 1);
  });
}
