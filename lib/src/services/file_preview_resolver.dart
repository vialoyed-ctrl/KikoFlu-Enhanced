import 'dart:io';

import 'download_file_path_service.dart';
import '../utils/file_tree_utils.dart';
import '../utils/local_file_url.dart';

typedef PreviewDownloadRootProvider = Future<String> Function();
typedef PreviewFileExists = Future<bool> Function(String path);

class PreviewFileItem {
  const PreviewFileItem({
    required this.url,
    required this.title,
    required this.hash,
  });

  final String url;
  final String title;
  final String hash;

  Map<String, String> toGalleryMap() {
    return {
      'url': url,
      'title': title,
      'hash': hash,
    };
  }
}

enum PreviewImageGalleryStatus {
  ready,
  missingOnlineInfo,
  missingSelectedImage,
  empty,
}

class PreviewImageGalleryTarget {
  const PreviewImageGalleryTarget({
    required this.items,
    required this.initialIndex,
  });

  final List<PreviewFileItem> items;
  final int initialIndex;

  List<Map<String, String>> toGalleryMaps() {
    return items.map((item) => item.toGalleryMap()).toList();
  }
}

class PreviewImageGalleryResult {
  const PreviewImageGalleryResult._({
    required this.status,
    this.target,
  });

  factory PreviewImageGalleryResult.ready(
    PreviewImageGalleryTarget target,
  ) {
    return PreviewImageGalleryResult._(
      status: PreviewImageGalleryStatus.ready,
      target: target,
    );
  }

  const PreviewImageGalleryResult.failure(this.status) : target = null;

  final PreviewImageGalleryStatus status;
  final PreviewImageGalleryTarget? target;

  PreviewImageGalleryTarget get requireTarget {
    final value = target;
    if (value == null) {
      throw StateError('Image gallery target is unavailable for $status.');
    }
    return value;
  }
}

enum PreviewDocumentTargetStatus {
  ready,
  missingOnlineInfo,
  missingId,
  missingPath,
  missingFile,
  unavailable,
}

enum PreviewVideoTargetStatus {
  ready,
  missingId,
  missingParams,
  missingPath,
  missingFile,
}

class PreviewDocumentTarget {
  const PreviewDocumentTarget({
    required this.url,
    required this.title,
    required this.hash,
  });

  final String url;
  final String title;
  final String hash;
}

class PreviewDocumentTargetResult {
  const PreviewDocumentTargetResult._({
    required this.status,
    this.target,
    required this.title,
  });

  factory PreviewDocumentTargetResult.ready(PreviewDocumentTarget target) {
    return PreviewDocumentTargetResult._(
      status: PreviewDocumentTargetStatus.ready,
      target: target,
      title: target.title,
    );
  }

  factory PreviewDocumentTargetResult.failure(
    PreviewDocumentTargetStatus status, {
    required String title,
  }) {
    return PreviewDocumentTargetResult._(
      status: status,
      title: title,
    );
  }

  final PreviewDocumentTargetStatus status;
  final PreviewDocumentTarget? target;
  final String title;

  PreviewDocumentTarget get requireTarget {
    final value = target;
    if (value == null) {
      throw StateError('Preview target is unavailable for $status.');
    }
    return value;
  }
}

class PreviewVideoTarget {
  const PreviewVideoTarget({
    required this.source,
    this.localPath,
  });

  final String source;
  final String? localPath;

  bool get isLocalFile =>
      localPath != null || LocalFileUrl.isLocalFileUrl(source);
}

class PreviewVideoTargetResult {
  const PreviewVideoTargetResult._({
    required this.status,
    this.target,
  });

  factory PreviewVideoTargetResult.ready(PreviewVideoTarget target) {
    return PreviewVideoTargetResult._(
      status: PreviewVideoTargetStatus.ready,
      target: target,
    );
  }

  const PreviewVideoTargetResult.failure(this.status) : target = null;

  final PreviewVideoTargetStatus status;
  final PreviewVideoTarget? target;

  PreviewVideoTarget get requireTarget {
    final value = target;
    if (value == null) {
      throw StateError('Video target is unavailable for $status.');
    }
    return value;
  }
}

class LocalPreviewFile {
  const LocalPreviewFile({
    required this.relativePath,
    required this.path,
    required this.exists,
  });

  final String relativePath;
  final String path;
  final bool exists;

  String get url => LocalFileUrl.fromPath(path);
}

class FilePreviewResolver {
  const FilePreviewResolver({
    required this.downloadRootPath,
    this.fileExists = _defaultFileExists,
  });

  final PreviewDownloadRootProvider downloadRootPath;
  final PreviewFileExists fileExists;

  static String normalizeHost(String host) {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host;
    }
    return 'https://$host';
  }

  static String mediaStreamUrl({
    required String host,
    required String hash,
    required String token,
  }) {
    return '${normalizeHost(host)}/api/media/stream/$hash?token=$token';
  }

  Future<String?> resolveOnlineUrl({
    required int workId,
    required String hash,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
    bool allowNetwork = true,
  }) async {
    final localUrl = await _resolveDownloadedLocalUrl(
      workId: workId,
      hash: hash,
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
    );
    if (localUrl != null) return localUrl;

    if (!allowNetwork) return null;
    return mediaStreamUrl(host: host, hash: hash, token: token);
  }

  Future<PreviewDocumentTargetResult> resolveOnlineDocumentTarget({
    required dynamic file,
    required int workId,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
    required String unknownTitle,
    bool allowNetwork = true,
  }) async {
    final title = FileTreeUtils.titleOf(file, defaultValue: unknownTitle);
    final hash = FileTreeUtils.property(file, 'hash')?.toString();

    if (hash == null || hash.isEmpty || host.isEmpty) {
      return PreviewDocumentTargetResult.failure(
        PreviewDocumentTargetStatus.missingOnlineInfo,
        title: title,
      );
    }

    final url = await resolveOnlineUrl(
      workId: workId,
      hash: hash,
      host: host,
      token: token,
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
      allowNetwork: allowNetwork,
    );
    if (url == null) {
      return PreviewDocumentTargetResult.failure(
        PreviewDocumentTargetStatus.unavailable,
        title: title,
      );
    }

    return PreviewDocumentTargetResult.ready(
      PreviewDocumentTarget(url: url, title: title, hash: hash),
    );
  }

  Future<PreviewVideoTargetResult> resolveOnlineVideoTarget({
    required dynamic file,
    required int workId,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
  }) async {
    final hash = FileTreeUtils.property(file, 'hash')?.toString() ?? '';

    if (hash.isEmpty) {
      return const PreviewVideoTargetResult.failure(
        PreviewVideoTargetStatus.missingId,
      );
    }

    final source = await resolveOnlineUrl(
      workId: workId,
      hash: hash,
      host: host,
      token: token,
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
      allowNetwork: host.isNotEmpty && token.isNotEmpty,
    );

    if (source == null) {
      return const PreviewVideoTargetResult.failure(
        PreviewVideoTargetStatus.missingParams,
      );
    }

    return PreviewVideoTargetResult.ready(
      PreviewVideoTarget(
        source: source,
        localPath: LocalFileUrl.pathFromUrl(source),
      ),
    );
  }

  Future<List<PreviewFileItem>> buildOnlineImageItems({
    required List<dynamic> imageFiles,
    required int workId,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
    required String unknownTitle,
  }) async {
    final items = <PreviewFileItem>[];

    for (final file in imageFiles) {
      final hash = FileTreeUtils.property(file, 'hash')?.toString() ?? '';
      final title = FileTreeUtils.titleOf(file, defaultValue: unknownTitle);
      final url = await resolveOnlineUrl(
        workId: workId,
        hash: hash,
        host: host,
        token: token,
        downloadedFiles: downloadedFiles,
        fileRelativePaths: fileRelativePaths,
      );

      if (url == null) continue;
      items.add(PreviewFileItem(url: url, title: title, hash: hash));
    }

    return items;
  }

  Future<PreviewImageGalleryResult> buildOnlineImageGalleryTarget({
    required dynamic selectedFile,
    required List<dynamic> imageFiles,
    required int workId,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
    required String unknownTitle,
  }) async {
    if (host.isEmpty) {
      return const PreviewImageGalleryResult.failure(
        PreviewImageGalleryStatus.missingOnlineInfo,
      );
    }

    final selectedHash =
        FileTreeUtils.property(selectedFile, 'hash')?.toString();
    final initialIndex = imageFiles.indexWhere(
      (file) =>
          FileTreeUtils.property(file, 'hash')?.toString() == selectedHash,
    );

    if (initialIndex == -1) {
      return const PreviewImageGalleryResult.failure(
        PreviewImageGalleryStatus.missingSelectedImage,
      );
    }

    final items = await buildOnlineImageItems(
      imageFiles: imageFiles,
      workId: workId,
      host: host,
      token: token,
      downloadedFiles: downloadedFiles,
      fileRelativePaths: fileRelativePaths,
      unknownTitle: unknownTitle,
    );

    return PreviewImageGalleryResult.ready(
      PreviewImageGalleryTarget(items: items, initialIndex: initialIndex),
    );
  }

  Future<LocalPreviewFile?> resolveOfflineLocalFile({
    required List<dynamic> fileTree,
    required int workId,
    required String hash,
    String? workDirPath,
  }) async {
    final relativePath = FileTreeUtils.relativePathForHash(fileTree, hash);
    if (relativePath == null) return null;

    final workDir = await _resolveWorkDirPath(workId, workDirPath);
    final localPath = DownloadFilePathService.localPathForRelativePath(
      rootPath: workDir,
      relativePath: relativePath,
    );
    return LocalPreviewFile(
      relativePath: relativePath,
      path: localPath,
      exists: await fileExists(localPath),
    );
  }

  Future<PreviewDocumentTargetResult> resolveOfflineDocumentTarget({
    required dynamic file,
    required List<dynamic> fileTree,
    required int workId,
    required String unknownTitle,
    String? workDirPath,
  }) async {
    final title = FileTreeUtils.titleOf(file, defaultValue: unknownTitle);
    final hashValue = FileTreeUtils.property(file, 'hash');

    if (hashValue == null) {
      return PreviewDocumentTargetResult.failure(
        PreviewDocumentTargetStatus.missingId,
        title: title,
      );
    }

    final hash = hashValue.toString();
    final localFile = await resolveOfflineLocalFile(
      fileTree: fileTree,
      workId: workId,
      hash: hash,
      workDirPath: workDirPath,
    );
    if (localFile == null) {
      return PreviewDocumentTargetResult.failure(
        PreviewDocumentTargetStatus.missingPath,
        title: title,
      );
    }

    if (!localFile.exists) {
      return PreviewDocumentTargetResult.failure(
        PreviewDocumentTargetStatus.missingFile,
        title: title,
      );
    }

    return PreviewDocumentTargetResult.ready(
      PreviewDocumentTarget(url: localFile.url, title: title, hash: hash),
    );
  }

  Future<PreviewVideoTargetResult> resolveOfflineVideoTarget({
    required dynamic file,
    required List<dynamic> fileTree,
    required int workId,
    String? workDirPath,
  }) async {
    final hashValue = FileTreeUtils.property(file, 'hash');

    if (hashValue == null) {
      return const PreviewVideoTargetResult.failure(
        PreviewVideoTargetStatus.missingId,
      );
    }

    final localFile = await resolveOfflineLocalFile(
      fileTree: fileTree,
      workId: workId,
      hash: hashValue.toString(),
      workDirPath: workDirPath,
    );
    if (localFile == null) {
      return const PreviewVideoTargetResult.failure(
        PreviewVideoTargetStatus.missingPath,
      );
    }

    if (!localFile.exists) {
      return const PreviewVideoTargetResult.failure(
        PreviewVideoTargetStatus.missingFile,
      );
    }

    return PreviewVideoTargetResult.ready(
      PreviewVideoTarget(
        source: localFile.url,
        localPath: localFile.path,
      ),
    );
  }

  Future<String?> resolveOfflineLocalUrl({
    required List<dynamic> fileTree,
    required int workId,
    required String hash,
    String? workDirPath,
  }) async {
    final file = await resolveOfflineLocalFile(
      fileTree: fileTree,
      workId: workId,
      hash: hash,
      workDirPath: workDirPath,
    );
    if (file == null || !file.exists) return null;
    return file.url;
  }

  Future<List<PreviewFileItem>> buildOfflineImageItems({
    required List<dynamic> imageFiles,
    required List<dynamic> fileTree,
    required int workId,
    required String unknownTitle,
    String? workDirPath,
  }) async {
    final items = <PreviewFileItem>[];

    for (final file in imageFiles) {
      final hash = FileTreeUtils.property(file, 'hash')?.toString() ?? '';
      final localUrl = await resolveOfflineLocalUrl(
        fileTree: fileTree,
        workId: workId,
        hash: hash,
        workDirPath: workDirPath,
      );
      if (localUrl == null) continue;

      items.add(PreviewFileItem(
        url: localUrl,
        title: FileTreeUtils.titleOf(file, defaultValue: unknownTitle),
        hash: hash,
      ));
    }

    return items;
  }

  Future<PreviewImageGalleryResult> buildOfflineImageGalleryTarget({
    required dynamic selectedFile,
    required List<dynamic> imageFiles,
    required List<dynamic> fileTree,
    required int workId,
    required String unknownTitle,
    String? workDirPath,
  }) async {
    final selectedHash =
        FileTreeUtils.property(selectedFile, 'hash')?.toString();
    final selectedIndex = imageFiles.indexWhere(
      (file) =>
          FileTreeUtils.property(file, 'hash')?.toString() == selectedHash,
    );

    if (selectedIndex == -1) {
      return const PreviewImageGalleryResult.failure(
        PreviewImageGalleryStatus.missingSelectedImage,
      );
    }

    final items = await buildOfflineImageItems(
      imageFiles: imageFiles,
      fileTree: fileTree,
      workId: workId,
      unknownTitle: unknownTitle,
      workDirPath: workDirPath,
    );

    if (items.isEmpty) {
      return const PreviewImageGalleryResult.failure(
        PreviewImageGalleryStatus.empty,
      );
    }

    final adjustedIndex = items.indexWhere((item) => item.hash == selectedHash);

    return PreviewImageGalleryResult.ready(
      PreviewImageGalleryTarget(
        items: items,
        initialIndex: adjustedIndex != -1 ? adjustedIndex : 0,
      ),
    );
  }

  Future<String?> _resolveDownloadedLocalUrl({
    required int workId,
    required String hash,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
  }) async {
    final relativePath = fileRelativePaths[hash];
    if (relativePath == null || downloadedFiles[hash] != true) {
      return null;
    }

    try {
      final rootPath = await downloadRootPath();
      final localPath = DownloadFilePathService.localPathForWorkRelativePath(
        rootPath: rootPath,
        workId: workId,
        relativePath: relativePath,
      );
      if (await fileExists(localPath)) {
        return LocalFileUrl.fromPath(localPath);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<String> _resolveWorkDirPath(int workId, String? workDirPath) async {
    final explicitPath = workDirPath?.trim();
    if (explicitPath != null && explicitPath.isNotEmpty) {
      return explicitPath;
    }

    return DownloadFilePathService.localPathForRelativePath(
      rootPath: await downloadRootPath(),
      relativePath: workId.toString(),
    );
  }

  static Future<bool> _defaultFileExists(String path) {
    return File(path).exists();
  }
}
