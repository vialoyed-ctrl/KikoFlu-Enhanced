import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/file_tree_view.dart';

Map<String, dynamic> fileItem(
  String title, {
  String? type,
  String? hash,
}) {
  return {
    'type': type ?? 'file',
    'title': title,
    if (hash != null) 'hash': hash,
  };
}

Map<String, dynamic> folderItem(
  String title,
  List<dynamic> children,
) {
  return {
    'type': 'folder',
    'title': title,
    'children': children,
  };
}

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('FileTreeView expands folders and passes file tap context',
      (tester) async {
    final tree = [
      folderItem('Disc 1', [
        fileItem('track01.mp3', type: 'audio', hash: 'audio-hash'),
      ]),
    ];
    String? toggledPath;
    String? tappedTitle;
    String? tappedParent;

    await tester.pumpWidget(
      _testApp(
        FileTreeView(
          items: tree,
          expandedFolders: const {},
          displayNameFor: (title) => 'translated $title',
          onToggleFolder: (path) => toggledPath = path,
          onFileTap: (_, title, parentPath) {
            tappedTitle = title;
            tappedParent = parentPath;
          },
        ),
      ),
    );

    expect(find.text('translated Disc 1'), findsOneWidget);
    expect(find.text('translated track01.mp3'), findsNothing);

    await tester.tap(find.text('translated Disc 1'));
    expect(toggledPath, 'Disc 1');

    await tester.pumpWidget(
      _testApp(
        FileTreeView(
          items: tree,
          expandedFolders: const {'Disc 1'},
          displayNameFor: (title) => 'translated $title',
          onToggleFolder: (path) => toggledPath = path,
          onFileTap: (_, title, parentPath) {
            tappedTitle = title;
            tappedParent = parentPath;
          },
        ),
      ),
    );

    await tester.tap(find.text('translated track01.mp3'));
    expect(tappedTitle, 'translated track01.mp3');
    expect(tappedParent, 'Disc 1');
  });

  testWidgets('FileTreeView renders metadata, trailing actions, and badges',
      (tester) async {
    final tree = [
      fileItem('track01.mp3', type: 'audio', hash: 'audio-hash'),
    ];

    await tester.pumpWidget(
      _testApp(
        FileTreeView(
          items: tree,
          expandedFolders: const {},
          downloadedFiles: const {'audio-hash': true},
          audioWithLibrarySubtitles: const {'track01.mp3'},
          showDownloadedBadge: true,
          fadeDownloadedItems: true,
          metadataBuilder: (_, __) => const Text('01:23'),
          trailingBuilder: (_, __) => IconButton(
            key: const Key('play-action'),
            icon: const Icon(Icons.play_arrow),
            onPressed: () {},
          ),
          onToggleFolder: (_) {},
          onFileTap: (_, __, ___) {},
        ),
      ),
    );

    expect(find.text('track01.mp3'), findsOneWidget);
    expect(find.text('01:23'), findsOneWidget);
    expect(find.byKey(const Key('play-action')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.subtitles), findsOneWidget);
  });
}
