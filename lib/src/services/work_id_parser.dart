class WorkIdParser {
  const WorkIdParser._();

  static List<String> extractRJIds(String text) {
    if (text.isEmpty) return [];

    final rjPattern = RegExp(r'RJ\d+', caseSensitive: false);
    final matches = rjPattern.allMatches(text.toUpperCase());

    return matches.map((match) => match.group(0)!).toSet().toList();
  }
}
