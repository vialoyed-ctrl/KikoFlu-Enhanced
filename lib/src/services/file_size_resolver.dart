import 'dart:io';

import 'download_file_path_service.dart';
import '../utils/file_tree_utils.dart';

typedef FileSizeDownloadRootProvider = Future<String> Function();
typedef FileSizeLengthReader = Future<int?> Function(String path);

class FileSizeResolver {
  const FileSizeResolver({
    required this.downloadRootPath,
    this.fileLength = _defaultFileLength,
  });

  final FileSizeDownloadRootProvider downloadRootPath;
  final FileSizeLengthReader fileLength;

  Future<int?> resolveOffline({
    required dynamic item,
    required int workId,
    required String parentPath,
    String? workDirPath,
  }) async {
    final metaSize = FileTreeUtils.property(item, 'size');
    if (metaSize is int && metaSize > 0) {
      return metaSize;
    }

    final title = FileTreeUtils.titleOf(item);
    if (title.isEmpty) return null;

    try {
      final workDir = workDirPath ??
          DownloadFilePathService.localPathForRelativePath(
            rootPath: await downloadRootPath(),
            relativePath: workId.toString(),
          );
      final filePath = DownloadFilePathService.localPathForRelativePath(
        rootPath: workDir,
        relativePath: DownloadFilePathService.localRelativePathForItem(
          item,
          parentPath,
        ),
      );

      return await fileLength(filePath);
    } catch (_) {
      return null;
    }
  }

  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '$bytes B';
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  static Future<int?> _defaultFileLength(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    return file.length();
  }
}
