class SubtitleLibraryTree {
  const SubtitleLibraryTree._();

  static Set<String> collectPaths(List<Map<String, dynamic>> items) {
    final paths = <String>{};
    _collectPathsInto(items, paths);
    return paths;
  }

  static Set<String> collectChildPaths(Map<String, dynamic> folder) {
    final children = childrenOf(folder);
    if (children == null) return {};

    return collectPaths(children);
  }

  static List<Map<String, dynamic>> filterFiles(
    List<Map<String, dynamic>> files,
    String query,
  ) {
    if (query.isEmpty) return files;

    final normalizedQuery = query.toLowerCase();
    final filtered = <Map<String, dynamic>>[];

    for (final file in files) {
      final isFolder = file['type'] == 'folder';
      final title = (file['title'] ?? '').toString();
      final matches = title.toLowerCase().contains(normalizedQuery);

      if (!isFolder) {
        if (matches) filtered.add(file);
        continue;
      }

      final filteredChildren = filterFiles(
        childrenOf(file) ?? const [],
        query,
      );

      if (matches || filteredChildren.isNotEmpty) {
        filtered.add({
          ...file,
          'children': filteredChildren,
        });
      }
    }

    return filtered;
  }

  static List<Map<String, dynamic>> currentFiles({
    required List<Map<String, dynamic>> files,
    required String currentPath,
    required String? rootPath,
  }) {
    if (files.isEmpty) return [];
    if (currentPath == rootPath || currentPath.isEmpty) return files;

    return findChildren(files, currentPath) ?? [];
  }

  static List<Map<String, dynamic>>? findChildren(
    List<Map<String, dynamic>> nodes,
    String targetPath,
  ) {
    for (final node in nodes) {
      if (node['path'] == targetPath) {
        return childrenOf(node);
      }

      if (node['type'] != 'folder' || node['children'] == null) continue;

      final nodePath = node['path'] as String;
      if (!targetPath.startsWith(nodePath)) continue;

      final result = findChildren(childrenOf(node) ?? const [], targetPath);
      if (result != null) return result;
    }

    return null;
  }

  static List<Map<String, dynamic>>? childrenOf(Map<String, dynamic> item) {
    return (item['children'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
  }

  static void _collectPathsInto(
    List<Map<String, dynamic>> items,
    Set<String> paths,
  ) {
    for (final item in items) {
      paths.add(item['path'] as String);
      final children = childrenOf(item);
      if (item['type'] == 'folder' && children != null) {
        _collectPathsInto(children, paths);
      }
    }
  }
}
