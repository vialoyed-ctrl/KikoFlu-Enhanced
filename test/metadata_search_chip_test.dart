import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/widgets/metadata_search_chip.dart';
import 'package:kikoeru_flutter/src/widgets/tag_chip.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('MetadataSearchChip', () {
    testWidgets('renders an action chip and runs the provided tap callback', (
      tester,
    ) async {
      var tapped = 0;

      await tester.pumpWidget(
        _testApp(
          MetadataSearchChip(
            label: 'Tag',
            searchKeyword: 'Tag',
            searchTypeLabel: 'Tag',
            searchParams: const {'tagId': 1},
            chipTone: MetadataChipTone.secondary,
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('Tag'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      expect(tapped, 1);
    });

    testWidgets('renders an input chip and runs the delete callback', (
      tester,
    ) async {
      var deleted = 0;

      await tester.pumpWidget(
        _testApp(
          MetadataSearchChip(
            label: 'Circle',
            searchKeyword: 'Circle',
            searchTypeLabel: 'Circle',
            searchParams: const {'circleId': 2},
            chipTone: MetadataChipTone.secondary,
            onDeleted: () => deleted++,
          ),
        ),
      );

      expect(find.byType(InputChip), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, 1);
    });

    testWidgets('uses compact custom style and long press callback', (
      tester,
    ) async {
      var longPressed = 0;

      await tester.pumpWidget(
        _testApp(
          MetadataSearchChip(
            label: 'VA',
            searchKeyword: 'VA',
            searchTypeLabel: 'VA',
            searchParams: const {'vaId': 3},
            chipTone: MetadataChipTone.tertiary,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: 6,
            onLongPress: () => longPressed++,
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byType(GestureDetector), findsOneWidget);

      final text = tester.widget<Text>(find.text('VA'));
      expect(text.style?.fontSize, 12);

      await tester.longPress(find.text('VA'));
      expect(longPressed, 1);
    });
  });

  group('metadata chip wrappers', () {
    testWidgets(
      'long pressing a list tag offers copy and copies visible name',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = call.arguments['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          _testApp(const TagChip(tag: Tag(id: 999999, name: 'ASMR'))),
        );
        await tester.longPress(find.text('ASMR'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.copy), findsOneWidget);
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();
        expect(copied, 'ASMR');
      },
    );
    testWidgets('TagChip delegates rendering and custom tap handling', (
      tester,
    ) async {
      var tapped = 0;

      await tester.pumpWidget(
        _testApp(
          TagChip(
            tag: const Tag(id: 999999, name: 'custom tag'),
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('custom tag'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      expect(tapped, 1);
    });
  });
}
