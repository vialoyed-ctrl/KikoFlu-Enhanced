import 'dart:io';

import 'download_file_path_service.dart';
import '../utils/file_tree_utils.dart';

typedef DownloadedPathResolver = Future<String?> Function(
  int workId,
  String hash,
);
typedef DownloadRootPathProvider = Future<String> Function();
typedef DownloadedFileExists = Future<bool> Function(String path);

class DownloadedFileState {
  const DownloadedFileState({
    required this.downloadedFiles,
    required this.fileRelativePaths,
  });

  final Map<String, bool> downloadedFiles;
  final Map<String, String> fileRelativePaths;
}

class DownloadedFileStateScanner {
  const DownloadedFileStateScanner({
    required this.resolveDownloadedPath,
    required this.downloadRootPath,
    this.fileExists = _defaultFileExists,
  });

  final DownloadedPathResolver resolveDownloadedPath;
  final DownloadRootPathProvider downloadRootPath;
  final DownloadedFileExists fileExists;

  Future<DownloadedFileState> scan({
    required int workId,
    required List<dynamic> fileTree,
  }) async {
    final downloadedFiles = <String, bool>{};
    final fileRelativePaths = <String, String>{};

    _collectFilePaths(
      fileTree,
      '',
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
    );

    final rootPath = await downloadRootPath();

    for (final hash in List<String>.from(downloadedFiles.keys)) {
      final downloadedPath = await resolveDownloadedPath(workId, hash);
      if (downloadedPath != null) {
        downloadedFiles[hash] = true;
        continue;
      }

      final relativePath = fileRelativePaths[hash];
      if (relativePath == null) continue;

      final localPath = DownloadFilePathService.localPathForWorkRelativePath(
        rootPath: rootPath,
        workId: workId,
        relativePath: relativePath,
      );
      if (await fileExists(localPath)) {
        downloadedFiles[hash] = true;
      }
    }

    return DownloadedFileState(
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
    );
  }

  static void _collectFilePaths(
    List<dynamic> items,
    String parentPath, {
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
  }) {
    for (final item in items) {
      final isFolder = FileTreeUtils.isFolder(item);
      final hash = FileTreeUtils.property(item, 'hash')?.toString();

      if (!isFolder && hash != null) {
        downloadedFiles[hash] = false;
        fileRelativePaths[hash] =
            FileTreeUtils.localRelativePathOf(item, parentPath);
      }

      final children = FileTreeUtils.childrenOf(item);
      if (children == null) continue;

      final nextPath = isFolder
          ? FileTreeUtils.localRelativePathOf(item, parentPath)
          : parentPath;
      _collectFilePaths(
        children,
        nextPath,
        downloadedFiles: downloadedFiles,
        fileRelativePaths: fileRelativePaths,
      );
    }
  }

  static Future<bool> _defaultFileExists(String path) {
    return File(path).exists();
  }
}
