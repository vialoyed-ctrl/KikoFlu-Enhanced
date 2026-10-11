import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/file_preview_resolver.dart';

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

void main() {
  group('FilePreviewResolver', () {
    test('normalizes host and builds media stream URLs', () {
      expect(
        FilePreviewResolver.mediaStreamUrl(
          host: 'example.test',
          hash: 'abc',
          token: 'token',
        ),
        'https://example.test/api/media/stream/abc?token=token',
      );
      expect(
        FilePreviewResolver.normalizeHost('http://example.test'),
        'http://example.test',
      );
    });

    test('online resolver prefers existing downloaded file', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/Disc 1/cover.jpg',
      );

      final url = await resolver.resolveOnlineUrl(
        workId: 123,
        hash: 'img',
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'img': true},
        fileRelativePaths: const {'img': 'Disc 1/cover.jpg'},
      );

      expect(url, 'file:///downloads/123/Disc 1/cover.jpg');
    });

    test('online resolver falls back to network when local file is unavailable',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );

      final url = await resolver.resolveOnlineUrl(
        workId: 123,
        hash: 'img',
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'img': true},
        fileRelativePaths: const {'img': 'Disc 1/cover.jpg'},
      );

      expect(url, 'https://example.test/api/media/stream/img?token=token');
    });

    test('online document target exposes ready preview details', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/docs/readme.txt',
      );

      final result = await resolver.resolveOnlineDocumentTarget(
        file: fileItem('readme.txt', type: 'text', hash: 'txt'),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'txt': true},
        fileRelativePaths: const {'txt': 'docs/readme.txt'},
        unknownTitle: 'unknown',
      );

      expect(result.status, PreviewDocumentTargetStatus.ready);
      expect(result.requireTarget.url, 'file:///downloads/123/docs/readme.txt');
      expect(result.requireTarget.title, 'readme.txt');
      expect(result.requireTarget.hash, 'txt');
    });

    test('online document target reports missing online information', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );

      final missingHash = await resolver.resolveOnlineDocumentTarget(
        file: fileItem('readme.txt', type: 'text'),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
        unknownTitle: 'unknown',
      );
      final missingHost = await resolver.resolveOnlineDocumentTarget(
        file: fileItem('book.pdf', type: 'pdf', hash: 'pdf'),
        workId: 123,
        host: '',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
        unknownTitle: 'unknown',
      );

      expect(missingHash.status, PreviewDocumentTargetStatus.missingOnlineInfo);
      expect(missingHost.status, PreviewDocumentTargetStatus.missingOnlineInfo);
    });

    test('online image gallery target keeps selected image index', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path.endsWith('cover.jpg'),
      );

      final imageFiles = [
        fileItem('cover.jpg', type: 'image', hash: 'cover'),
        fileItem('page.png', type: 'image', hash: 'page'),
      ];
      final result = await resolver.buildOnlineImageGalleryTarget(
        selectedFile: imageFiles.last,
        imageFiles: imageFiles,
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'cover': true},
        fileRelativePaths: const {'cover': 'Disc 1/cover.jpg'},
        unknownTitle: 'unknown',
      );

      expect(result.status, PreviewImageGalleryStatus.ready);
      expect(result.requireTarget.initialIndex, 1);
      expect(result.requireTarget.toGalleryMaps(), [
        {
          'url': 'file:///downloads/123/Disc 1/cover.jpg',
          'title': 'cover.jpg',
          'hash': 'cover',
        },
        {
          'url': 'https://example.test/api/media/stream/page?token=token',
          'title': 'page.png',
          'hash': 'page',
        },
      ]);
    });

    test('online image gallery target reports missing prerequisites', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );
      final imageFiles = [
        fileItem('cover.jpg', type: 'image', hash: 'cover'),
      ];

      final missingHost = await resolver.buildOnlineImageGalleryTarget(
        selectedFile: imageFiles.single,
        imageFiles: imageFiles,
        workId: 123,
        host: '',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
        unknownTitle: 'unknown',
      );
      final missingSelected = await resolver.buildOnlineImageGalleryTarget(
        selectedFile: fileItem('page.png', type: 'image', hash: 'page'),
        imageFiles: imageFiles,
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
        unknownTitle: 'unknown',
      );

      expect(missingHost.status, PreviewImageGalleryStatus.missingOnlineInfo);
      expect(
        missingSelected.status,
        PreviewImageGalleryStatus.missingSelectedImage,
      );
    });

    test('online video target prefers local files and reports failures',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path.endsWith('movie.mp4'),
      );

      final local = await resolver.resolveOnlineVideoTarget(
        file: fileItem('movie.mp4', type: 'video', hash: 'movie'),
        workId: 123,
        host: '',
        token: '',
        downloadedFiles: const {'movie': true},
        fileRelativePaths: const {'movie': 'Disc 1/movie.mp4'},
      );
      final missingParams = await resolver.resolveOnlineVideoTarget(
        file: fileItem('remote.mp4', type: 'video', hash: 'remote'),
        workId: 123,
        host: '',
        token: '',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );
      final missingId = await resolver.resolveOnlineVideoTarget(
        file: fileItem('unknown.mp4', type: 'video'),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );

      expect(local.status, PreviewVideoTargetStatus.ready);
      expect(
          local.requireTarget.source, 'file:///downloads/123/Disc 1/movie.mp4');
      expect(local.requireTarget.localPath, '/downloads/123/Disc 1/movie.mp4');
      expect(missingParams.status, PreviewVideoTargetStatus.missingParams);
      expect(missingId.status, PreviewVideoTargetStatus.missingId);
    });

    test('online video target falls back to remote source when possible',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );

      final result = await resolver.resolveOnlineVideoTarget(
        file: fileItem('movie.mp4', type: 'video', hash: 'movie'),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );

      expect(result.status, PreviewVideoTargetStatus.ready);
      expect(
        result.requireTarget.source,
        'https://example.test/api/media/stream/movie?token=token',
      );
      expect(result.requireTarget.localPath, isNull);
    });

    test('offline resolver distinguishes missing path from missing file',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('book.pdf', type: 'pdf', hash: 'pdf'),
        ]),
      ];

      final found = await resolver.resolveOfflineLocalFile(
        fileTree: tree,
        workId: 123,
        hash: 'pdf',
      );
      final missing = await resolver.resolveOfflineLocalFile(
        fileTree: tree,
        workId: 123,
        hash: 'missing',
      );

      expect(found?.relativePath, 'Disc 1/book.pdf');
      expect(found?.path, '/downloads/123/Disc 1/book.pdf');
      expect(found?.exists, isFalse);
      expect(missing, isNull);
    });

    test('offline resolver uses localRelativePath for sanitized downloads',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '/downloads/123/docs_/book_.pdf',
      );
      final tree = [
        folderItem('docs?', [
          {
            'type': 'pdf',
            'title': 'book?.pdf',
            'hash': 'pdf',
            'localRelativePath': 'docs_/book_.pdf',
          },
        ]),
      ];

      final local = await resolver.resolveOfflineLocalFile(
        fileTree: tree,
        workId: 123,
        hash: 'pdf',
      );
      final target = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('book?.pdf', type: 'pdf', hash: 'pdf'),
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );

      expect(local?.relativePath, 'docs_/book_.pdf');
      expect(local?.path, '/downloads/123/docs_/book_.pdf');
      expect(local?.exists, isTrue);
      expect(target.status, PreviewDocumentTargetStatus.ready);
      expect(target.requireTarget.title, 'book?.pdf');
      expect(target.requireTarget.url, 'file:///downloads/123/docs_/book_.pdf');
    });

    test('offline resolver can use an imported RJ work directory', () async {
      const workDir = '/downloads/[circle][RJ123456]Title';
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path == '$workDir/docs/book.pdf',
      );
      final tree = [
        folderItem('docs', [
          fileItem('book.pdf', type: 'pdf', hash: 'pdf'),
        ]),
      ];

      final local = await resolver.resolveOfflineLocalFile(
        fileTree: tree,
        workId: 123456,
        hash: 'pdf',
        workDirPath: workDir,
      );
      final target = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('book.pdf', type: 'pdf', hash: 'pdf'),
        fileTree: tree,
        workId: 123456,
        unknownTitle: 'unknown',
        workDirPath: workDir,
      );

      expect(local?.path, '$workDir/docs/book.pdf');
      expect(local?.exists, isTrue);
      expect(target.status, PreviewDocumentTargetStatus.ready);
      expect(target.requireTarget.url, 'file://$workDir/docs/book.pdf');
    });

    test(
        'offline document target distinguishes failure states and ready target',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path.endsWith('ready.pdf'),
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('missing.pdf', type: 'pdf', hash: 'missing'),
          fileItem('ready.pdf', type: 'pdf', hash: 'ready'),
        ]),
      ];

      final missingId = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('unknown.pdf', type: 'pdf'),
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );
      final missingPath = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('ghost.pdf', type: 'pdf', hash: 'ghost'),
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );
      final missingFile = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('missing.pdf', type: 'pdf', hash: 'missing'),
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );
      final ready = await resolver.resolveOfflineDocumentTarget(
        file: fileItem('ready.pdf', type: 'pdf', hash: 'ready'),
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );

      expect(missingId.status, PreviewDocumentTargetStatus.missingId);
      expect(missingPath.status, PreviewDocumentTargetStatus.missingPath);
      expect(missingFile.status, PreviewDocumentTargetStatus.missingFile);
      expect(missingFile.title, 'missing.pdf');
      expect(ready.status, PreviewDocumentTargetStatus.ready);
      expect(ready.requireTarget.url, 'file:///downloads/123/Disc 1/ready.pdf');
      expect(ready.requireTarget.hash, 'ready');
    });

    test('offline image builder includes only existing local images', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path.endsWith('cover.jpg'),
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('cover.jpg', type: 'image', hash: 'cover'),
          fileItem('missing.png', type: 'image', hash: 'missing'),
        ]),
      ];

      final items = await resolver.buildOfflineImageItems(
        imageFiles: [
          fileItem('cover.jpg', type: 'image', hash: 'cover'),
          fileItem('missing.png', type: 'image', hash: 'missing'),
        ],
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );

      expect(items.map((item) => item.toGalleryMap()), [
        {
          'url': 'file:///downloads/123/Disc 1/cover.jpg',
          'title': 'cover.jpg',
          'hash': 'cover',
        },
      ]);
    });

    test('offline image gallery target adjusts index after missing files',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) => Future.value(
          path.endsWith('cover.jpg') || path.endsWith('page2.png'),
        ),
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('cover.jpg', type: 'image', hash: 'cover'),
          fileItem('missing.png', type: 'image', hash: 'missing'),
          fileItem('page2.png', type: 'image', hash: 'page2'),
        ]),
      ];
      final imageFiles = [
        fileItem('cover.jpg', type: 'image', hash: 'cover'),
        fileItem('missing.png', type: 'image', hash: 'missing'),
        fileItem('page2.png', type: 'image', hash: 'page2'),
      ];

      final result = await resolver.buildOfflineImageGalleryTarget(
        selectedFile: imageFiles.last,
        imageFiles: imageFiles,
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );

      expect(result.status, PreviewImageGalleryStatus.ready);
      expect(result.requireTarget.initialIndex, 1);
      expect(result.requireTarget.toGalleryMaps(), [
        {
          'url': 'file:///downloads/123/Disc 1/cover.jpg',
          'title': 'cover.jpg',
          'hash': 'cover',
        },
        {
          'url': 'file:///downloads/123/Disc 1/page2.png',
          'title': 'page2.png',
          'hash': 'page2',
        },
      ]);
    });

    test('offline image gallery target reports missing and empty states',
        () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (_) async => false,
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('cover.jpg', type: 'image', hash: 'cover'),
        ]),
      ];
      final imageFiles = [
        fileItem('cover.jpg', type: 'image', hash: 'cover'),
      ];

      final missingSelected = await resolver.buildOfflineImageGalleryTarget(
        selectedFile: fileItem('page.png', type: 'image', hash: 'page'),
        imageFiles: imageFiles,
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );
      final empty = await resolver.buildOfflineImageGalleryTarget(
        selectedFile: imageFiles.single,
        imageFiles: imageFiles,
        fileTree: tree,
        workId: 123,
        unknownTitle: 'unknown',
      );

      expect(
        missingSelected.status,
        PreviewImageGalleryStatus.missingSelectedImage,
      );
      expect(empty.status, PreviewImageGalleryStatus.empty);
    });

    test('offline video target distinguishes local file states', () async {
      final resolver = FilePreviewResolver(
        downloadRootPath: () async => '/downloads',
        fileExists: (path) async => path.endsWith('ready.mp4'),
      );
      final tree = [
        folderItem('Disc 1', [
          fileItem('missing.mp4', type: 'video', hash: 'missing'),
          fileItem('ready.mp4', type: 'video', hash: 'ready'),
        ]),
      ];

      final missingId = await resolver.resolveOfflineVideoTarget(
        file: fileItem('unknown.mp4', type: 'video'),
        fileTree: tree,
        workId: 123,
      );
      final missingPath = await resolver.resolveOfflineVideoTarget(
        file: fileItem('ghost.mp4', type: 'video', hash: 'ghost'),
        fileTree: tree,
        workId: 123,
      );
      final missingFile = await resolver.resolveOfflineVideoTarget(
        file: fileItem('missing.mp4', type: 'video', hash: 'missing'),
        fileTree: tree,
        workId: 123,
      );
      final ready = await resolver.resolveOfflineVideoTarget(
        file: fileItem('ready.mp4', type: 'video', hash: 'ready'),
        fileTree: tree,
        workId: 123,
      );

      expect(missingId.status, PreviewVideoTargetStatus.missingId);
      expect(missingPath.status, PreviewVideoTargetStatus.missingPath);
      expect(missingFile.status, PreviewVideoTargetStatus.missingFile);
      expect(ready.status, PreviewVideoTargetStatus.ready);
      expect(
          ready.requireTarget.source, 'file:///downloads/123/Disc 1/ready.mp4');
      expect(ready.requireTarget.localPath, '/downloads/123/Disc 1/ready.mp4');
    });
  });
}
