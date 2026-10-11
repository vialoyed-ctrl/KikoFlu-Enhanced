class FileNameTranslationController {
  FileNameTranslationController();

  final Map<String, String> translations = {};
  final Set<String> pendingNames = {};

  bool showTranslation = false;
  bool isBulkTranslating = false;
  String progress = '';
  int _generation = 0;

  int get translationCount => translations.length;

  void dispose() {
    _generation++;
    pendingNames.clear();
    isBulkTranslating = false;
    progress = '';
  }

  void toggleShowTranslation() {
    showTranslation = !showTranslation;
  }

  bool toggleExistingTranslations() {
    if (translations.isEmpty) return false;
    toggleShowTranslation();
    return true;
  }

  String displayName(
    String originalName, {
    void Function(String originalName)? onMissingTranslation,
  }) {
    if (showTranslation && translations.containsKey(originalName)) {
      return translations[originalName]!;
    }

    if (showTranslation) {
      onMissingTranslation?.call(originalName);
    }

    return originalName;
  }

  int beginBulkTranslation(String initialProgress) {
    _generation++;
    isBulkTranslating = true;
    progress = initialProgress;
    return _generation;
  }

  bool updateBulkProgress(int generation, String nextProgress) {
    if (!_isCurrent(generation)) return false;
    progress = nextProgress;
    return true;
  }

  bool completeBulkTranslation(
    int generation,
    Map<String, String> nextTranslations,
  ) {
    if (!_isCurrent(generation)) return false;
    translations
      ..clear()
      ..addAll(nextTranslations);
    showTranslation = true;
    isBulkTranslating = false;
    progress = '';
    return true;
  }

  bool finishBulkWithoutTranslations(int generation) {
    if (!_isCurrent(generation)) return false;
    isBulkTranslating = false;
    progress = '';
    return true;
  }

  bool failBulkTranslation(int generation) {
    if (!_isCurrent(generation)) return false;
    isBulkTranslating = false;
    progress = '';
    return true;
  }

  int? beginLazyTranslation(String originalName) {
    if (translations.containsKey(originalName) ||
        pendingNames.contains(originalName)) {
      return null;
    }

    pendingNames.add(originalName);
    return _generation;
  }

  bool completeLazyTranslation(
    int generation,
    String originalName,
    String translatedName,
  ) {
    if (!_isCurrent(generation)) return false;
    translations[originalName] = translatedName;
    pendingNames.remove(originalName);
    return true;
  }

  bool failLazyTranslation(int generation, String originalName) {
    if (!_isCurrent(generation)) return false;
    pendingNames.remove(originalName);
    return true;
  }

  bool _isCurrent(int generation) {
    return generation == _generation;
  }
}
