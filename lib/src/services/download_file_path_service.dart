import 'package:path/path.dart' as p;

import '../utils/file_tree_utils.dart';

class DownloadFilePathService {
  DownloadFilePathService._();

  static const int maxSegmentLength = 80;
  static const String localRelativePathKey = 'localRelativePath';

  static final RegExp _invalidCharacters = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _reservedWindowsNames = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?$',
    caseSensitive: false,
  );
  static final RegExp _windowsDriveSegment = RegExp(r'^[a-zA-Z]:');

  static String safeRelativePath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) {
          final trimmed = segment.trim();
          return trimmed.isNotEmpty && trimmed != '.' && trimmed != '..';
        })
        .map(safePathSegment)
        .where((segment) => segment.isNotEmpty)
        .toList();

    return segments.isEmpty ? 'download' : segments.join('/');
  }

  static String safePathSegment(String segment) {
    var safe = segment
        .replaceAll(_invalidCharacters, '_')
        .replaceAll(_whitespace, ' ')
        .trim();

    safe = safe.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
    safe = safe.replaceAll(RegExp(r'_+'), '_');

    if (safe.isEmpty) safe = 'download';
    if (_reservedWindowsNames.hasMatch(safe)) safe = '_$safe';

    if (safe.length > maxSegmentLength) {
      safe = _truncatePreservingExtension(safe, maxSegmentLength);
    }

    return safe;
  }

  static String? localRelativePathOf(dynamic item) {
    if (item == null) return null;

    if (item is Map) {
      final value = item[localRelativePathKey];
      if (value is String && value.trim().isNotEmpty) {
        return normalizeRelativePath(value);
      }

      final relativePath = item['relativePath'];
      if (relativePath is String && relativePath.trim().isNotEmpty) {
        return normalizeRelativePath(relativePath);
      }

      return null;
    }

    final value = FileTreeUtils.property(item, localRelativePathKey);
    if (value is String && value.trim().isNotEmpty) {
      return normalizeRelativePath(value);
    }

    final relativePath = FileTreeUtils.property(item, 'relativePath');
    if (relativePath is String && relativePath.trim().isNotEmpty) {
      return normalizeRelativePath(relativePath);
    }

    return null;
  }

  static String localRelativePathForItem(
    dynamic item,
    String parentPath, {
    String defaultTitle = 'download',
  }) {
    final storedPath = localRelativePathOf(item);
    if (storedPath != null) return storedPath;

    final title = FileTreeUtils.titleOf(item, defaultValue: defaultTitle);
    return parentPath.isEmpty
        ? normalizeRelativePath(title)
        : normalizeRelativePath('$parentPath/$title');
  }

  static String localPathForItem({
    required String rootPath,
    required int workId,
    required dynamic item,
    String parentPath = '',
  }) {
    return localPathForWorkRelativePath(
      rootPath: rootPath,
      workId: workId,
      relativePath: localRelativePathForItem(item, parentPath),
    );
  }

  static String localPathForWorkRelativePath({
    required String rootPath,
    required int workId,
    required String relativePath,
    p.Context? context,
  }) {
    final pathContext = context ?? p.context;
    return localPathForRelativePath(
      rootPath: pathContext.join(rootPath, workId.toString()),
      relativePath: relativePath,
      context: pathContext,
    );
  }

  static String localPathForRelativePath({
    required String rootPath,
    required String relativePath,
    p.Context? context,
  }) {
    final pathContext = context ?? p.context;
    final segments = relativePathSegments(relativePath);
    if (segments.isEmpty) return rootPath;

    return pathContext.joinAll([rootPath, ...segments]);
  }

  static List<dynamic> annotateFileTreeWithLocalPaths(List<dynamic> fileTree) {
    final seenPaths = <String>{};
    return _annotateItems(
      fileTree,
      displayParentPath: '',
      localParentPath: '',
      seenPaths: seenPaths,
    );
  }

  static Map<String, String> localRelativePathsByHash(List<dynamic> fileTree) {
    final paths = <String, String>{};

    void collect(List<dynamic> items) {
      for (final item in items) {
        final hash = FileTreeUtils.property(item, 'hash')?.toString();
        final localRelativePath = localRelativePathOf(item);
        if (hash != null && localRelativePath != null) {
          paths[hash] = localRelativePath;
        }

        final children = FileTreeUtils.childrenOf(item);
        if (children != null) collect(children);
      }
    }

    collect(fileTree);
    return paths;
  }

  static String normalizeRelativePath(String relativePath) {
    return relativePathSegments(relativePath).join('/');
  }

  static List<String> relativePathSegments(String relativePath) {
    return relativePath
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) {
          final trimmed = segment.trim();
          return trimmed.isNotEmpty && trimmed != '.' && trimmed != '..';
        })
        .map(_neutralizePathRootSegment)
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }

  static String? parentPathOf(String relativePath) {
    final normalized = normalizeRelativePath(relativePath);
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '';
    return normalized.substring(0, index);
  }

  static String _truncatePreservingExtension(String value, int maxLength) {
    if (value.length <= maxLength) return value;

    final extension = p.extension(value);
    if (extension.isNotEmpty && extension.length < maxLength - 8) {
      final baseLength = maxLength - extension.length;
      return '${value.substring(0, baseLength)}$extension';
    }

    return value.substring(0, maxLength);
  }

  static String _neutralizePathRootSegment(String segment) {
    final trimmed = segment.trim();
    if (_windowsDriveSegment.hasMatch(trimmed)) {
      return trimmed.replaceFirst(':', '_');
    }
    return segment;
  }

  static List<dynamic> _annotateItems(
    List<dynamic> items, {
    required String displayParentPath,
    required String localParentPath,
    required Set<String> seenPaths,
  }) {
    return items.map((item) {
      final title = FileTreeUtils.titleOf(item, defaultValue: 'download');
      final displayPath =
          displayParentPath.isEmpty ? title : '$displayParentPath/$title';
      final safeTitle = safePathSegment(title);
      final localPath =
          localParentPath.isEmpty ? safeTitle : '$localParentPath/$safeTitle';

      if (FileTreeUtils.isFolder(item)) {
        final children = FileTreeUtils.childrenOf(item) ?? const <dynamic>[];
        final mapped = _copyItem(item)
          ..[localRelativePathKey] = _dedupePath(localPath, seenPaths);
        mapped['children'] = _annotateItems(
          children,
          displayParentPath: displayPath,
          localParentPath: mapped[localRelativePathKey] as String,
          seenPaths: seenPaths,
        );
        return mapped;
      }

      final localFilePath = _dedupePath(localPath, seenPaths);
      return _copyItem(item)..[localRelativePathKey] = localFilePath;
    }).toList();
  }

  static Map<String, dynamic> _copyItem(dynamic item) {
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    return <String, dynamic>{
      'type': FileTreeUtils.typeOf(item),
      'title': FileTreeUtils.titleOf(item),
      if (FileTreeUtils.property(item, 'hash') != null)
        'hash': FileTreeUtils.property(item, 'hash'),
      if (FileTreeUtils.property(item, 'children') != null)
        'children': FileTreeUtils.property(item, 'children'),
      if (FileTreeUtils.property(item, 'size') != null)
        'size': FileTreeUtils.property(item, 'size'),
      if (FileTreeUtils.property(item, 'duration') != null)
        'duration': FileTreeUtils.property(item, 'duration'),
    };
  }

  static String _dedupePath(String path, Set<String> seenPaths) {
    final normalized = normalizeRelativePath(path);
    if (seenPaths.add(normalized)) return normalized;

    final parent = parentPathOf(normalized) ?? '';
    final name =
        parent.isEmpty ? normalized : normalized.substring(parent.length + 1);
    final extension = p.extension(name);
    final baseName = extension.isEmpty
        ? name
        : name.substring(0, name.length - extension.length);

    var index = 2;
    while (true) {
      final candidateName = '$baseName ($index)$extension';
      final candidate =
          parent.isEmpty ? candidateName : '$parent/$candidateName';
      if (seenPaths.add(candidate)) return candidate;
      index++;
    }
  }
}
