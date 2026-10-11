import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_service.dart';
import 'package:kikoeru_flutter/src/widgets/subtitle_library_file_list.dart';

Map<String, dynamic> _folder(
  String title,
  String path,
  List<Map<String, dynamic>> children,
) {
  return {
    'type': 'folder',
    'title': title,
    'path': path,
    'children': children,
  };
}

Map<String, dynamic> _file(
  String title,
  String path, {
  int? size,
}) {
  return {
    'type': 'text',
    'title': title,
    'path': path,
    if (size != null) 'size': size,
  };
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );
}

void main() {
  testWidgets('renders localized folder and handles default actions',
      (tester) async {
    final items = [
      _folder(
        SubtitleLibraryService.parsedFolderName,
        '/library/parsed',
        [_file('line.lrc', '/library/parsed/line.lrc')],
      ),
    ];

    String? folderTap;
    String? optionsPath;

    await tester.pumpWidget(
      _testApp(
        SubtitleLibraryFileList(
          items: items,
          selectedPaths: const {},
          selectionMode: false,
          recursive: false,
          onRefresh: () async {},
          onSelectionToggle: (_, __, ___) {},
          onFolderTap: (path) => folderTap = path,
          onPreviewFile: (_) {},
          onLoadSubtitle: (_) {},
          onShowOptions: (_, path) => optionsPath = path,
        ),
      ),
    );

    expect(find.text('Parsed'), findsOneWidget);
    expect(find.text('line.lrc'), findsNothing);

    await tester.tap(find.text('Parsed'));
    await tester.tap(find.byIcon(Icons.more_vert));

    expect(folderTap, '/library/parsed');
    expect(optionsPath, '/library/parsed');
  });

  testWidgets('renders recursive files and dispatches subtitle actions',
      (tester) async {
    final subtitle = _file(
      'line.lrc',
      '/library/parsed/line.lrc',
      size: 1536,
    );
    final items = [
      _folder('RJ123456', '/library/parsed/RJ123456', [subtitle]),
    ];

    String? previewPath;
    String? optionsPath;
    Map<String, dynamic>? loadedItem;

    await tester.pumpWidget(
      _testApp(
        SubtitleLibraryFileList(
          items: items,
          selectedPaths: const {},
          selectionMode: false,
          recursive: true,
          onRefresh: () async {},
          onSelectionToggle: (_, __, ___) {},
          onFolderTap: (_) {},
          onPreviewFile: (path) => previewPath = path,
          onLoadSubtitle: (item) => loadedItem = item,
          onShowOptions: (_, path) => optionsPath = path,
        ),
      ),
    );

    expect(find.text('RJ123456'), findsOneWidget);
    expect(find.text('line.lrc'), findsOneWidget);
    expect(find.text('1.5 KB'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.subtitles));
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.tap(find.byIcon(Icons.more_vert).last);

    expect(loadedItem, subtitle);
    expect(previewPath, '/library/parsed/line.lrc');
    expect(optionsPath, '/library/parsed/line.lrc');
  });

  testWidgets('selection mode toggles rows instead of previewing',
      (tester) async {
    final subtitle = _file('line.lrc', '/library/parsed/line.lrc');
    final items = [
      _folder('RJ123456', '/library/parsed/RJ123456', [subtitle]),
    ];

    String? selectedPath;
    var previewCount = 0;

    await tester.pumpWidget(
      _testApp(
        SubtitleLibraryFileList(
          items: items,
          selectedPaths: const {'/library/parsed/line.lrc'},
          selectionMode: true,
          recursive: true,
          onRefresh: () async {},
          onSelectionToggle: (path, _, __) => selectedPath = path,
          onFolderTap: (_) {},
          onPreviewFile: (_) => previewCount++,
          onLoadSubtitle: (_) {},
          onShowOptions: (_, __) {},
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('line.lrc'));

    expect(selectedPath, '/library/parsed/line.lrc');
    expect(previewCount, 0);
  });
}
