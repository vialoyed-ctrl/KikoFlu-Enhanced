import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/models/search_type.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/providers/auth_provider.dart';
import 'package:kikoeru_flutter/src/providers/search_history_provider.dart';
import 'package:kikoeru_flutter/src/providers/subtitle_library_provider.dart';
import 'package:kikoeru_flutter/src/screens/search_screen.dart';
import 'package:kikoeru_flutter/src/services/kikoeru_api_service.dart'
    hide kikoeruApiServiceProvider;
import 'package:kikoeru_flutter/src/widgets/tag_chip.dart';
import 'package:kikoeru_flutter/src/widgets/kiko_search_field.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_dropdown.dart';

class _Library extends SubtitleLibraryNotifier {
  @override
  Future<void> refresh() async {}
}

class _Api extends KikoeruApiService {
  String? lastQuery;
  @override
  Future<List<dynamic>> getAllTags() async => [
    {'id': 497, 'name': 'ASMR'},
  ];
  @override
  Future<List<dynamic>> getAllVas() async => [];
  @override
  Future<List<dynamic>> getAllCircles() async => [];
  @override
  Future<Map<String, dynamic>> searchWorks({
    required String keyword,
    int page = 1,
    int pageSize = 40,
    String? order,
    String? sort,
    int? subtitle,
    int? seed,
    bool includeTranslationWorks = true,
  }) async {
    lastQuery = keyword;
    return {
      'works': [],
      'pagination': {'totalCount': 0, 'currentPage': 1},
    };
  }
}

void main() {
  testWidgets(
    'home search hub keeps history, has no Add flow, and records tag clicks',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'liquid_glass_navigation_enabled': false,
      });
      final api = _Api();
      final container = ProviderContainer(
        overrides: [
          kikoeruApiServiceProvider.overrideWithValue(api),
          currentTrackProvider.overrideWith((ref) => Stream.value(null)),
          subtitleLibraryProvider.overrideWith((ref) => _Library()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('添加'), findsNothing);
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      expect(find.text('添加'), findsNothing);
      await tester.enterText(find.byType(TextField), 'rain wind');
      await tester.tap(find.widgetWithText(FilledButton, '搜索'));
      await tester.pumpAndSettle();
      expect(api.lastQuery, 'rain wind');
      expect(
        container.read(searchHistoryProvider).items.first.displayText,
        'rain wind',
      );
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('搜索历史'), findsOneWidget);
      await tester.tap(
        find.byType(LiquidGlassDropdownButtonFormField<AgeRating>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('成人向').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rain');
      await tester.tap(find.widgetWithText(FilledButton, '搜索'));
      await tester.pumpAndSettle();
      expect(api.lastQuery, r'rain $age:adult$');
      await tester.tap(
        find.descendant(
          of: find.byType(KikoSearchField),
          matching: find.byIcon(Icons.search),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.lastQuery, r'rain $age:adult$');
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: TagChip(tag: Tag(id: 497, name: 'ASMR')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ASMR'));
      await tester.pumpAndSettle();
      expect(api.lastQuery, r'$tag:ASMR$');
      expect(
        container.read(searchHistoryProvider).items.map((item) => item.keyword),
        [r'$tag:ASMR$', r'rain $age:adult$', 'rain wind'],
      );
    },
  );
}
