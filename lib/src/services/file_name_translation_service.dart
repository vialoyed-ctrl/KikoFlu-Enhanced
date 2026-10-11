import '../utils/file_tree_utils.dart';

typedef FileNameTranslator = Future<String> Function(
  String text, {
  String? sourceLang,
});
typedef FileNameTranslationDelay = Future<void> Function(Duration duration);
typedef FileNameTranslationProgress = void Function(int current, int total);
typedef FileNameTranslationError = void Function(int index, Object error);

class FileNameTranslationResult {
  const FileNameTranslationResult({
    required this.names,
    required this.translations,
  });

  final List<String> names;
  final Map<String, String> translations;

  bool get isEmpty => names.isEmpty;
}

class FileNameTranslationService {
  const FileNameTranslationService({
    required this.translate,
    this.delay = _defaultDelay,
  });

  final FileNameTranslator translate;
  final FileNameTranslationDelay delay;

  Future<FileNameTranslationResult> translateFileTree({
    required List<dynamic> fileTree,
    String sourceLang = 'ja',
    int maxChunkSize = 500,
    Duration throttleDelay = const Duration(milliseconds: 300),
    FileNameTranslationProgress? onProgress,
    FileNameTranslationError? onChunkError,
  }) async {
    final names = FileTreeUtils.collectNames(fileTree);
    if (names.isEmpty) {
      return const FileNameTranslationResult(
        names: [],
        translations: {},
      );
    }

    final chunks = splitNamesIntoChunks(
      names,
      maxChunkSize: maxChunkSize,
    );
    final translatedChunks = <String>[];

    for (var i = 0; i < chunks.length; i++) {
      onProgress?.call(i + 1, chunks.length);

      try {
        translatedChunks.add(
          await translate(chunks[i], sourceLang: sourceLang),
        );
      } catch (e) {
        onChunkError?.call(i, e);
        translatedChunks.add(chunks[i]);
      }

      if (i < chunks.length - 1) {
        await delay(throttleDelay);
      }
    }

    final translatedNames = translatedChunks.join('\n').split('\n');
    final translations = <String, String>{};

    for (var i = 0; i < names.length && i < translatedNames.length; i++) {
      translations[names[i]] = translatedNames[i];
    }

    return FileNameTranslationResult(
      names: names,
      translations: translations,
    );
  }

  static List<String> splitNamesIntoChunks(
    List<String> names, {
    required int maxChunkSize,
  }) {
    final chunks = <String>[];
    var currentChunk = '';

    for (final name in names) {
      final separator = currentChunk.isEmpty ? '' : '\n';
      final estimatedLength =
          currentChunk.length + separator.length + name.length;

      if (estimatedLength > maxChunkSize && currentChunk.isNotEmpty) {
        chunks.add(currentChunk);
        currentChunk = name;
      } else {
        currentChunk += separator + name;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks;
  }

  static Future<void> _defaultDelay(Duration duration) {
    return Future.delayed(duration);
  }
}
