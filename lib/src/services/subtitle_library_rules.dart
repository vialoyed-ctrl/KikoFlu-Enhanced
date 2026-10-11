import 'package:archive/archive.dart';

class SubtitleLibraryRules {
  static const int maxPathLength = 240;

  static const String parsedFolderName = '已解析';
  static const String unknownFolderName = '未知作品';
  static const String savedFolderName = '已保存';

  static final _workFolderPatterns = [
    RegExp(r'^[RrBbVv][Jj]\d{6,8}$'),
    RegExp(r'^\d{6,8}$'),
  ];

  static bool matchesWorkFolderName(String folderName) {
    return _workFolderPatterns.any((pattern) => pattern.hasMatch(folderName));
  }

  static String normalizeWorkFolderName(String folderName) {
    final pureNumberPattern = RegExp(r'^\d{6,8}$');
    if (pureNumberPattern.hasMatch(folderName)) {
      return 'RJ$folderName';
    }

    final prefixedPattern =
        RegExp(r'^([rbv])j(\d{6,8})$', caseSensitive: false);
    final match = prefixedPattern.firstMatch(folderName);
    if (match != null) {
      final prefix = match.group(1)!.toUpperCase();
      final numbers = match.group(2)!;
      return '${prefix}J$numbers';
    }

    return folderName;
  }

  static Set<String> archiveRootItems(Archive archive) {
    final rootItems = <String>{};

    for (final file in archive.files) {
      if (!file.isFile && file.name.isEmpty) continue;

      final parts = file.name.split('/');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        rootItems.add(parts.first);
      }
    }

    return rootItems;
  }

  static bool shouldCreateNewFolderForArchive(
    Archive archive,
    String archiveName,
  ) {
    return shouldCreateNewFolder(archiveRootItems(archive), archiveName);
  }

  static bool shouldCreateNewFolder(
    Iterable<String> rootItems,
    String archiveName,
  ) {
    final uniqueRootItems = rootItems.toSet();
    if (uniqueRootItems.length != 1) {
      return true;
    }

    return uniqueRootItems.first != archiveName;
  }
}
