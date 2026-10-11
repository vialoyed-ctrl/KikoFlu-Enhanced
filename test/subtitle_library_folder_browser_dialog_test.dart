import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_service.dart';
import 'package:kikoeru_flutter/src/widgets/subtitle_library_folder_browser_dialog.dart';

Map<String, dynamic> _folder(String name, String path) {
  return {'name': name, 'path': path};
}

Widget _testApp({
  required SubtitleLibraryFolderLoader folderLoader,
  String? excludePath,
  ValueChanged<String?>? onSelected,
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
              onPressed: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SubtitleLibraryFolderBrowserDialog(
                    rootPath: '/root',
                    excludePath: excludePath,
                    folderLoader: folderLoader,
                    pathSeparator: '/',
                  ),
                );
                onSelected?.call(selected);
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('loads folders, filters excluded paths, and selects current path',
      (tester) async {
    const parsedPath = '/root/${SubtitleLibraryService.parsedFolderName}';
    final calls = <String>[];
    String? selectedPath;

    await tester.pumpWidget(
      _testApp(
        excludePath: '/root/excluded',
        onSelected: (path) => selectedPath = path,
        folderLoader: (path) async {
          calls.add(path);
          if (path == '/root') {
            return [
              _folder(SubtitleLibraryService.parsedFolderName, parsedPath),
              _folder('excluded', '/root/excluded'),
              _folder('nested', '/root/excluded/nested'),
            ];
          }
          if (path == parsedPath) {
            return [_folder('Deep', '$parsedPath/Deep')];
          }
          return [];
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(calls, ['/root']);
    expect(find.text('Parsed'), findsOneWidget);
    expect(find.text('excluded'), findsNothing);
    expect(find.text('nested'), findsNothing);

    await tester.tap(find.text('Parsed'));
    await tester.pumpAndSettle();

    expect(calls, ['/root', parsedPath]);
    expect(find.text('Deep'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    expect(selectedPath, parsedPath);
  });

  testWidgets('shows an empty state when loader returns no folders',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        folderLoader: (_) async => [],
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('No subfolders in this directory'), findsOneWidget);
  });
}
