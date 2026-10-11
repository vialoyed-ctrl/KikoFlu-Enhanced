import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/kiko_search.dart';
import 'package:kikoeru_flutter/src/providers/auth_provider.dart';
import 'package:kikoeru_flutter/src/services/kikoeru_api_service.dart'
    hide kikoeruApiServiceProvider;
import 'package:kikoeru_flutter/src/widgets/kiko_search_field.dart';

class _CatalogApi extends KikoeruApiService {
  @override
  Future<List<dynamic>> getAllTags() async => [
    {'id': 497, 'name': 'ASMR'},
    {'id': 500, 'name': 'Voice'},
  ];
  @override
  Future<List<dynamic>> getAllVas() async => [
    {'id': 'v', 'name': 'Voice'},
  ];
  @override
  Future<List<dynamic>> getAllCircles() async => [
    {'id': 2, 'name': 'Circle'},
  ];
}

void main() {
  testWidgets(
    'typing and submitting searches immediately without adding a condition',
    (tester) async {
      KikoSearchQuery? submitted;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kikoeruApiServiceProvider.overrideWithValue(_CatalogApi()),
          ],
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: KikoSearchField(onSearch: (query) => submitted = query),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rain');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted?.keyword, 'rain');
      await tester.enterText(find.byType(TextField), 'AS');
      await tester.pumpAndSettle();
      expect(find.text('-ASMR'), findsOneWidget);
      await tester.tap(find.text('-ASMR'));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted?.keyword, r'$-tag:ASMR$');
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'selected VA identity survives an identical tag label and edits',
    (tester) async {
      KikoSearchQuery? submitted;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kikoeruApiServiceProvider.overrideWithValue(_CatalogApi()),
          ],
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: KikoSearchField(onSearch: (q) => submitted = q),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Voi');
      await tester.pumpAndSettle();
      final row = find.ancestor(
        of: find.byIcon(Icons.person_outline).first,
        matching: find.byType(ListTile),
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Voice rain');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted?.keyword, r'$va:Voice$ rain');
      await tester.enterText(find.byType(TextField), 'Voices rain');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted?.keyword, 'Voices rain');
    },
  );
  testWidgets(
    'a result or history restores metadata identity from its canonical query',
    (tester) async {
      KikoSearchQuery? submitted;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kikoeruApiServiceProvider.overrideWithValue(_CatalogApi()),
          ],
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: KikoSearchField(
                initialText: 'Voice',
                initialKeyword: r'$va:Voice$',
                onSearch: (q) => submitted = q,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Voice rain');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted?.keyword, r'$va:Voice$ rain');
    },
  );
}
