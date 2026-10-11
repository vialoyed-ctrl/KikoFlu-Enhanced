import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/file_explorer_tree_panel.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders header, progress, and file tree when ready',
      (tester) async {
    String? tappedTitle;
    String? toggledPath;

    await tester.pumpWidget(
      _testApp(
        FileExplorerTreePanel(
          isLoading: false,
          empty: false,
          emptyMessage: 'No files',
          title: 'Resource Files',
          trailing: IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {},
          ),
          progressMessage: 'Translating 1/2',
          items: const [
            {
              'type': 'folder',
              'title': 'Disc 1',
              'children': [
                {
                  'type': 'text',
                  'title': 'script.txt',
                  'hash': 'text',
                },
              ],
            },
          ],
          expandedFolders: const {'Disc 1'},
          onToggleFolder: (path) {
            toggledPath = path;
          },
          onFileTap: (_, title, __) {
            tappedTitle = title;
          },
        ),
      ),
    );

    expect(find.text('Resource Files'), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.text('Translating 1/2'), findsOneWidget);
    expect(find.text('Disc 1'), findsOneWidget);
    expect(find.text('script.txt'), findsOneWidget);

    await tester.tap(find.text('script.txt'));
    expect(tappedTitle, 'script.txt');

    await tester.tap(find.text('Disc 1'));
    expect(toggledPath, 'Disc 1');
  });

  testWidgets('loading state hides panel content', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const FileExplorerTreePanel(
          isLoading: true,
          empty: false,
          emptyMessage: 'No files',
          title: 'Resource Files',
          items: [],
          expandedFolders: {},
          onToggleFolder: _noopString,
          onFileTap: _noopTap,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Resource Files'), findsNothing);
  });
}

void _noopString(String _) {}

void _noopTap(dynamic _, String __, String ___) {}
