import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../utils/file_icon_utils.dart';
import '../utils/file_tree_utils.dart';
import '../utils/snackbar_util.dart';

typedef FileTreeDisplayNameBuilder = String Function(String originalTitle);
typedef FileTreeItemTap = void Function(
  dynamic item,
  String displayTitle,
  String parentPath,
);
typedef FileTreeMetadataBuilder = Widget? Function(
  BuildContext context,
  FileTreeEntry entry,
);
typedef FileTreeTrailingBuilder = Widget? Function(
  BuildContext context,
  FileTreeEntry entry,
);

class FileTreeEntry {
  const FileTreeEntry({
    required this.item,
    required this.parentPath,
    required this.itemPath,
    required this.originalTitle,
    required this.displayTitle,
    required this.isFolder,
    required this.isExpanded,
    required this.children,
    required this.level,
  });

  final dynamic item;
  final String parentPath;
  final String itemPath;
  final String originalTitle;
  final String displayTitle;
  final bool isFolder;
  final bool isExpanded;
  final List<dynamic>? children;
  final int level;
}

class FileTreeView extends StatelessWidget {
  const FileTreeView({
    super.key,
    required this.items,
    required this.expandedFolders,
    required this.onToggleFolder,
    required this.onFileTap,
    this.displayNameFor,
    this.metadataBuilder,
    this.trailingBuilder,
    this.downloadedFiles = const {},
    this.audioWithLibrarySubtitles = const {},
    this.showDownloadedBadge = false,
    this.fadeDownloadedItems = false,
  });

  final List<dynamic> items;
  final Set<String> expandedFolders;
  final ValueChanged<String> onToggleFolder;
  final FileTreeItemTap onFileTap;
  final FileTreeDisplayNameBuilder? displayNameFor;
  final FileTreeMetadataBuilder? metadataBuilder;
  final FileTreeTrailingBuilder? trailingBuilder;
  final Map<String, bool> downloadedFiles;
  final Set<String> audioWithLibrarySubtitles;
  final bool showDownloadedBadge;
  final bool fadeDownloadedItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _buildEntries(context, items, '', level: 0),
    );
  }

  List<Widget> _buildEntries(
    BuildContext context,
    List<dynamic> currentItems,
    String parentPath, {
    required int level,
  }) {
    final widgets = <Widget>[];

    for (final item in currentItems) {
      final originalTitle = FileTreeUtils.titleOf(
        item,
        defaultValue: S.of(context).unknown,
      );
      final itemPath = FileTreeUtils.itemPath(parentPath, item);
      final entry = FileTreeEntry(
        item: item,
        parentPath: parentPath,
        itemPath: itemPath,
        originalTitle: originalTitle,
        displayTitle: displayNameFor?.call(originalTitle) ?? originalTitle,
        isFolder: FileTreeUtils.isFolder(item),
        isExpanded: expandedFolders.contains(itemPath),
        children: FileTreeUtils.childrenOf(item),
        level: level,
      );

      widgets.add(_FileTreeRow(
        entry: entry,
        metadata: metadataBuilder?.call(context, entry),
        trailing: trailingBuilder?.call(context, entry),
        downloaded: _isDownloaded(entry),
        showDownloadedBadge: showDownloadedBadge,
        fadeDownloadedItems: fadeDownloadedItems,
        hasLibrarySubtitle:
            audioWithLibrarySubtitles.contains(entry.originalTitle),
        onToggleFolder: onToggleFolder,
        onFileTap: onFileTap,
      ));

      final children = entry.children;
      if (entry.isFolder &&
          entry.isExpanded &&
          children != null &&
          children.isNotEmpty) {
        widgets.addAll(_buildEntries(
          context,
          children,
          itemPath,
          level: level + 1,
        ));
      }
    }

    return widgets;
  }

  bool _isDownloaded(FileTreeEntry entry) {
    if (entry.isFolder) return false;

    final hash = FileTreeUtils.property(entry.item, 'hash')?.toString();
    return hash != null && (downloadedFiles[hash] ?? false);
  }
}

class _FileTreeRow extends StatelessWidget {
  const _FileTreeRow({
    required this.entry,
    required this.metadata,
    required this.trailing,
    required this.downloaded,
    required this.showDownloadedBadge,
    required this.fadeDownloadedItems,
    required this.hasLibrarySubtitle,
    required this.onToggleFolder,
    required this.onFileTap,
  });

  final FileTreeEntry entry;
  final Widget? metadata;
  final Widget? trailing;
  final bool downloaded;
  final bool showDownloadedBadge;
  final bool fadeDownloadedItems;
  final bool hasLibrarySubtitle;
  final ValueChanged<String> onToggleFolder;
  final FileTreeItemTap onFileTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (entry.isFolder) {
          onToggleFolder(entry.itemPath);
        } else {
          onFileTap(entry.item, entry.displayTitle, entry.parentPath);
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.displayTitle));
        SnackBarUtil.showSuccess(
          context,
          S.of(context).copiedName(entry.displayTitle),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 8.0 + (entry.level * 20.0),
          right: 8,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            if (entry.isFolder)
              Icon(
                entry.isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
              )
            else
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            _FileTreeIcon(
              entry: entry,
              downloaded: downloaded,
              showDownloadedBadge: showDownloadedBadge,
              hasLibrarySubtitle: hasLibrarySubtitle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: fadeDownloadedItems && downloaded ? 0.5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (metadata != null) metadata!,
                  ],
                ),
              ),
            ),
            trailing ?? _FolderCount(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _FileTreeIcon extends StatelessWidget {
  const _FileTreeIcon({
    required this.entry,
    required this.downloaded,
    required this.showDownloadedBadge,
    required this.hasLibrarySubtitle,
  });

  final FileTreeEntry entry;
  final bool downloaded;
  final bool showDownloadedBadge;
  final bool hasLibrarySubtitle;

  @override
  Widget build(BuildContext context) {
    final fileMap = _asFileMap(entry.item);

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Icon(
            FileIconUtils.getFileIconFromMap(fileMap),
            color: FileIconUtils.getFileIconColorFromMap(fileMap),
            size: 24,
          ),
          if (showDownloadedBadge && downloaded)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 13,
                ),
              ),
            ),
          if (FileIconUtils.isAudioFile(fileMap) && hasLibrarySubtitle)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.subtitles,
                  color: Colors.blue[600],
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderCount extends StatelessWidget {
  const _FolderCount({required this.entry});

  final FileTreeEntry entry;

  @override
  Widget build(BuildContext context) {
    final children = entry.children;
    if (!entry.isFolder || children == null) {
      return const SizedBox.shrink();
    }

    return Text(
      S.of(context).nItems(children.length),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}

Map<String, dynamic> _asFileMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return item.cast<String, dynamic>();

  return {
    'type': FileTreeUtils.typeOf(item),
    'title': FileTreeUtils.titleOf(item),
    'hash': FileTreeUtils.property(item, 'hash'),
  };
}
