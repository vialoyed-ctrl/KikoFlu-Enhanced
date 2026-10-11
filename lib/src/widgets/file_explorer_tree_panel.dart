import 'package:flutter/material.dart';

import 'file_explorer_header.dart';
import 'file_explorer_status_view.dart';
import 'file_tree_view.dart';

class FileExplorerTreePanel extends StatelessWidget {
  const FileExplorerTreePanel({
    super.key,
    required this.isLoading,
    required this.empty,
    required this.emptyMessage,
    required this.title,
    required this.items,
    required this.expandedFolders,
    required this.onToggleFolder,
    required this.onFileTap,
    this.errorMessage,
    this.onRetry,
    this.trailing,
    this.progressMessage,
    this.displayNameFor,
    this.metadataBuilder,
    this.trailingBuilder,
    this.downloadedFiles = const {},
    this.audioWithLibrarySubtitles = const {},
    this.showDownloadedBadge = false,
    this.fadeDownloadedItems = false,
  });

  final bool isLoading;
  final bool empty;
  final String emptyMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String title;
  final Widget? trailing;
  final String? progressMessage;
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
    return FileExplorerStatusView(
      isLoading: isLoading,
      errorMessage: errorMessage,
      empty: empty,
      emptyMessage: emptyMessage,
      onRetry: onRetry,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileExplorerHeader(
              title: title,
              trailing: trailing,
            ),
            if (progressMessage != null && progressMessage!.isNotEmpty)
              FileExplorerProgressBanner(message: progressMessage!),
            FileTreeView(
              items: items,
              expandedFolders: expandedFolders,
              onToggleFolder: onToggleFolder,
              onFileTap: onFileTap,
              displayNameFor: displayNameFor,
              metadataBuilder: metadataBuilder,
              trailingBuilder: trailingBuilder,
              downloadedFiles: downloadedFiles,
              audioWithLibrarySubtitles: audioWithLibrarySubtitles,
              showDownloadedBadge: showDownloadedBadge,
              fadeDownloadedItems: fadeDownloadedItems,
            ),
          ],
        ),
      ),
    );
  }
}
