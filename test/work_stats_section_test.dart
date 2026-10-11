import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_stats_section.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

const _work = Work(
  id: 1,
  title: 'Work',
  rateAverage: 4.5,
  rateCount: 12,
  rateCountDetail: [
    RatingDetail(reviewPoint: 5, count: 10, ratio: 83),
  ],
  price: 770,
  duration: 65,
  dlCount: 12345,
);

void main() {
  testWidgets('renders configured rating, price, duration and sales',
      (tester) async {
    var detailTapCount = 0;
    var progressTapCount = 0;

    await tester.pumpWidget(
      _testApp(
        WorkStatsSection(
          work: _work,
          currentRating: 4,
          onShowRatingDetails: () => detailTapCount++,
          onShowProgress: () => progressTapCount++,
        ),
      ),
    );

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.textContaining('770'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(find.textContaining('1.2k'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.tap(find.byIcon(Icons.person));

    expect(detailTapCount, 1);
    expect(progressTapCount, 1);
  });

  testWidgets('hides optional stats when switches are disabled',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const WorkStatsSection(
          work: _work,
          showRating: false,
          showPrice: false,
          showDuration: false,
          showSales: false,
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.access_time), findsNothing);
    expect(find.textContaining('770'), findsNothing);
    expect(find.textContaining('1.2k'), findsNothing);
  });

  testWidgets('rating without details is not tappable', (tester) async {
    var detailTapCount = 0;

    await tester.pumpWidget(
      _testApp(
        const WorkStatsSection(
          work: Work(
            id: 2,
            title: 'No details',
            rateAverage: 0,
            rateCount: 0,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        WorkStatsSection(
          work: const Work(
            id: 2,
            title: 'No details',
            rateAverage: 0,
            rateCount: 0,
          ),
          onShowRatingDetails: () => detailTapCount++,
        ),
      ),
    );

    expect(find.text('-'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing);

    await tester.tap(find.byIcon(Icons.star));

    expect(detailTapCount, 0);
  });
}
