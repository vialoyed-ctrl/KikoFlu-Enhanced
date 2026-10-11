import 'dart:io';

import 'subtitle_availability_scanner.dart';
import 'subtitle_library_service.dart';

typedef SubtitleLibraryDirectoryProvider = Future<Directory> Function();

typedef SubtitleMatchFinder = Future<Set<String>> Function({
  required Directory libraryDir,
  required int workId,
  required List<dynamic> fileTree,
});

class SubtitleMatchLoader {
  const SubtitleMatchLoader({
    this.libraryDirectoryProvider =
        SubtitleLibraryService.getSubtitleLibraryDirectory,
    this.findMatches = _defaultFindMatches,
  });

  final SubtitleLibraryDirectoryProvider libraryDirectoryProvider;
  final SubtitleMatchFinder findMatches;

  Future<Set<String>> loadMatches({
    required int workId,
    required List<dynamic> fileTree,
  }) async {
    final libraryDir = await libraryDirectoryProvider();
    return findMatches(
      libraryDir: libraryDir,
      workId: workId,
      fileTree: fileTree,
    );
  }

  static Future<Set<String>> _defaultFindMatches({
    required Directory libraryDir,
    required int workId,
    required List<dynamic> fileTree,
  }) {
    return const SubtitleAvailabilityScanner().findAudioTitlesWithSubtitles(
      libraryDir: libraryDir,
      workId: workId,
      fileTree: fileTree,
    );
  }
}
