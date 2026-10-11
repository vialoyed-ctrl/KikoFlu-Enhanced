import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/playlist_edit_dialog.dart';

Widget _testApp({
  String initialName = 'Morning list',
  int initialPrivacy = 1,
  String initialDescription = 'Original notes',
  required ValueChanged<PlaylistMetadataDraft> onSave,
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
                  builder: (context) => PlaylistEditDialog(
                    initialName: initialName,
                    initialPrivacy: initialPrivacy,
                    initialDescription: initialDescription,
                    onSave: onSave,
                  ),
                );
              },
              child: const Text('Open edit playlist'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders initial playlist metadata', (tester) async {
    await tester.pumpWidget(_testApp(onSave: (_) {}));

    await tester.tap(find.text('Open edit playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Playlist'), findsOneWidget);
    expect(find.text('Playlist Name'), findsOneWidget);
    expect(find.text('Description (optional)'), findsOneWidget);
    expect(find.text('Unlisted'), findsOneWidget);
    expect(find.text('Only people with the link can view'), findsOneWidget);

    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey('playlist-edit-name')),
    );
    final descriptionField = tester.widget<TextField>(
      find.byKey(const ValueKey('playlist-edit-description')),
    );
    expect(nameField.controller?.text, 'Morning list');
    expect(descriptionField.controller?.text, 'Original notes');
  });

  testWidgets('submits trimmed metadata with selected privacy', (tester) async {
    PlaylistMetadataDraft? submittedDraft;
    await tester.pumpWidget(
      _testApp(
        onSave: (draft) {
          submittedDraft = draft;
        },
      ),
    );

    await tester.tap(find.text('Open edit playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('playlist-edit-name')),
      ' Updated list ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('playlist-edit-description')),
      ' Updated notes ',
    );
    await tester.tap(find.byKey(const ValueKey('playlist-edit-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public').last);
    await tester.pumpAndSettle();

    expect(find.text('Anyone can view'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(submittedDraft?.name, 'Updated list');
    expect(submittedDraft?.privacy, 2);
    expect(submittedDraft?.description, 'Updated notes');
    expect(find.text('Edit Playlist'), findsNothing);
  });

  testWidgets('keeps dialog open and warns when name is empty', (tester) async {
    PlaylistMetadataDraft? submittedDraft;
    await tester.pumpWidget(
      _testApp(
        onSave: (draft) {
          submittedDraft = draft;
        },
      ),
    );

    await tester.tap(find.text('Open edit playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('playlist-edit-name')),
      '   ',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(submittedDraft, isNull);
    expect(find.text('Edit Playlist'), findsOneWidget);
    expect(find.text('Playlist name cannot be empty'), findsOneWidget);
  });
}
