import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/subtitle_library_service.dart';
import '../utils/subtitle_library_display.dart';

typedef SubtitleLibraryFolderLoader = Future<List<Map<String, dynamic>>>
    Function(String path);

class SubtitleLibraryFolderBrowserDialog extends StatefulWidget {
  const SubtitleLibraryFolderBrowserDialog({
    super.key,
    required this.rootPath,
    this.excludePath,
    this.folderLoader,
    this.pathSeparator,
  });

  final String rootPath;
  final String? excludePath;
  final SubtitleLibraryFolderLoader? folderLoader;
  final String? pathSeparator;

  @override
  State<SubtitleLibraryFolderBrowserDialog> createState() =>
      _SubtitleLibraryFolderBrowserDialogState();
}

class _SubtitleLibraryFolderBrowserDialogState
    extends State<SubtitleLibraryFolderBrowserDialog> {
  final List<String> _pathStack = [];
  List<Map<String, dynamic>> _currentFolders = [];
  bool _loading = false;

  String get _separator => widget.pathSeparator ?? Platform.pathSeparator;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  String get _currentPath {
    if (_pathStack.isEmpty) {
      return widget.rootPath;
    }
    return _pathStack.last;
  }

  String _currentDisplayName(BuildContext context) {
    if (_pathStack.isEmpty) {
      return S.of(context).rootDirectory;
    }
    final name = _pathStack.last.split(_separator).last;
    final displayName = localizedSubtitleFolderTitle(context, name);
    if (displayName.length > 10) {
      return '${displayName.substring(0, 10)}...';
    }
    return displayName;
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);

    try {
      final loader =
          widget.folderLoader ?? SubtitleLibraryService.getSubFolders;
      final folders = await loader(_currentPath);
      final filteredFolders = _filterExcludedFolders(folders);

      if (!mounted) return;
      setState(() {
        _currentFolders = filteredFolders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filterExcludedFolders(
    List<Map<String, dynamic>> folders,
  ) {
    final excludePath = widget.excludePath;
    if (excludePath == null) return folders;

    return folders.where((folder) {
      final folderPath = folder['path'] as String;
      return folderPath != excludePath &&
          !folderPath.startsWith('$excludePath$_separator');
    }).toList();
  }

  void _navigateToFolder(String folderPath) {
    setState(() {
      _pathStack.add(folderPath);
    });
    _loadFolders();
  }

  void _navigateBack() {
    if (_pathStack.isEmpty) return;

    setState(() {
      _pathStack.removeLast();
    });
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (_pathStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _navigateBack,
              tooltip: S.of(context).goToParent,
            ),
          Expanded(
            child: Text(
              S.of(context).moveToTarget(_currentDisplayName(context)),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _currentFolders.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noSubfoldersHere,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _currentFolders.length,
                            itemBuilder: (context, index) {
                              final folder = _currentFolders[index];
                              final name = folder['name'] as String;
                              final displayName =
                                  localizedSubtitleFolderTitle(context, name);
                              final path = folder['path'] as String;

                              return ListTile(
                                leading: const Icon(
                                  Icons.folder,
                                  color: Colors.amber,
                                ),
                                title: Text(displayName),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _navigateToFolder(path),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(
              _currentDisplayName(context),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => Navigator.pop(context, _currentPath),
          ),
        ),
      ],
    );
  }
}
