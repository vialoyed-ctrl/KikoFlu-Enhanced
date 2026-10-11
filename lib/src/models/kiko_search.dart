import 'dart:ui';
import 'search_type.dart';
import '../utils/tag_localizer.dart';

class KikoSearchQuery {
  const KikoSearchQuery({required this.keyword, required this.displayText});
  final String keyword;
  final String displayText;
}

class KikoSearchSuggestion {
  const KikoSearchSuggestion({
    required this.type,
    required this.id,
    required this.name,
    this.translatedName,
    this.exclude = false,
  });
  final SearchType type;
  final Object id;
  final String name;
  final String? translatedName;
  final bool exclude;
  String label(Locale locale) => type == SearchType.tag
      ? translatedName ??
            TagLocalizer.localize(int.tryParse('$id') ?? 0, name, locale)
      : name;
  String display(Locale locale) => '${exclude ? '-' : ''}${label(locale)}';
  String get keyword => '\$${exclude ? '-' : ''}${type.name}:$name\$';
  KikoSearchSuggestion excluded() => KikoSearchSuggestion(
    type: type,
    id: id,
    name: name,
    translatedName: translatedName,
    exclude: true,
  );
}

class KikoSearchSelection {
  const KikoSearchSelection(this.start, this.end, this.suggestion);
  final int start;
  final int end;
  final KikoSearchSuggestion suggestion;
}

class KikoSearchCatalog {
  const KikoSearchCatalog(this.items);
  final List<KikoSearchSuggestion> items;

  List<KikoSearchSuggestion> suggest(String text, Locale locale) {
    final fragment = text.substring(fragmentStart(text, locale));
    final excluded = fragment.startsWith('-');
    final query = (excluded ? fragment.substring(1) : fragment).toLowerCase();
    if (query.isEmpty) return [];
    final matches = items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.label(locale).toLowerCase().contains(query),
        )
        .toList();
    matches.sort((a, b) {
      int rank(KikoSearchSuggestion item) {
        final names = [
          item.name.toLowerCase(),
          item.label(locale).toLowerCase(),
        ];
        if (names.contains(query)) return 0;
        if (names.any((name) => name.startsWith(query))) return 1;
        return 2;
      }

      final order = rank(a).compareTo(rank(b));
      return order != 0 ? order : items.indexOf(a).compareTo(items.indexOf(b));
    });
    return matches
        .take(12)
        .expand(
          (item) => excluded ? [item.excluded()] : [item, item.excluded()],
        )
        .toList();
  }

  String complete(String text, KikoSearchSuggestion suggestion, Locale locale) {
    final start = fragmentStart(text, locale, suggestion: suggestion);
    return '${text.substring(0, start)}${suggestion.display(locale)}';
  }

  int fragmentStart(
    String text,
    Locale locale, {
    KikoSearchSuggestion? suggestion,
  }) {
    final candidates = suggestion == null ? items : [suggestion];
    for (var start = 0; start < text.length; start++) {
      if (start > 0 && !RegExp(r'\s').hasMatch(text[start - 1])) continue;
      final fragment = text
          .substring(start)
          .replaceFirst(RegExp(r'^-'), '')
          .toLowerCase();
      if (fragment.isEmpty) continue;
      if (candidates.any(
        (item) =>
            item.name.toLowerCase().startsWith(fragment) ||
            item.label(locale).toLowerCase().startsWith(fragment),
      )) {
        return start;
      }
    }
    return text.lastIndexOf(RegExp(r'\s')) + 1;
  }

  List<KikoSearchSelection> restoreSelections(
    String text,
    String keyword,
    Locale locale,
  ) {
    final restored = <KikoSearchSelection>[];
    var cursor = 0;
    for (final token in RegExp(
      r'\$(-?)([a-zA-Z]+):([^$]+)\$|\S+',
    ).allMatches(keyword)) {
      if (token.group(2) == null) {
        final index = text.indexOf(token.group(0)!, cursor);
        if (index >= 0) cursor = index + token.group(0)!.length;
        continue;
      }
      final item = items
          .where(
            (item) =>
                item.type.name == token.group(2) && item.name == token.group(3),
          )
          .firstOrNull;
      if (item == null) continue;
      final selected = token.group(1) == '-' ? item.excluded() : item;
      final label = selected.display(locale);
      final index = text.indexOf(label, cursor);
      if (index >= 0) {
        restored.add(
          KikoSearchSelection(index, index + label.length, selected),
        );
        cursor = index + label.length;
      }
    }
    return restored;
  }

  KikoSearchQuery compile(
    String text,
    Locale locale, {
    List<KikoSearchSelection> selections = const [],
  }) {
    final display = text.trim();
    if (RegExp(r'^\d{6,}$').hasMatch(display)) {
      return KikoSearchQuery(keyword: 'RJ$display', displayText: 'RJ$display');
    }
    final aliases = <({String text, KikoSearchSuggestion item})>[];
    for (final item in items) {
      for (final alias in {item.name, item.label(locale)}) {
        if (alias.isNotEmpty) aliases.add((text: alias, item: item));
      }
    }
    aliases.sort((a, b) => b.text.length.compareTo(a.text.length));
    final parts = <String>[];
    var remaining = text;
    var cursor = 0;
    while (remaining.isNotEmpty) {
      final trimmed = remaining.trimLeft();
      cursor += remaining.length - trimmed.length;
      remaining = trimmed;
      if (remaining.isEmpty) break;
      final validSelections = selections
          .where(
            (s) =>
                s.start >= cursor &&
                s.end <= text.length &&
                text.substring(s.start, s.end) ==
                    s.suggestion.display(locale) &&
                (s.start == 0 || RegExp(r'\s').hasMatch(text[s.start - 1])) &&
                (s.end == text.length || RegExp(r'\s').hasMatch(text[s.end])),
          )
          .toList();
      final selected = validSelections
          .where(
            (s) =>
                s.start == cursor &&
                s.end <= text.length &&
                text.substring(s.start, s.end) ==
                    s.suggestion.display(locale) &&
                (s.end == text.length || RegExp(r'\s').hasMatch(text[s.end])),
          )
          .firstOrNull;
      if (selected != null) {
        parts.add(selected.suggestion.keyword);
        remaining = remaining.substring(selected.end - cursor);
        cursor = selected.end;
        continue;
      }
      final structured = RegExp(
        r'^\$-?[a-zA-Z]+:[^$]+\$',
      ).firstMatch(remaining);
      if (structured != null) {
        parts.add(structured.group(0)!);
        remaining = remaining.substring(structured.end);
        cursor += structured.end;
        continue;
      }
      final exclude = remaining.startsWith('-');
      final candidate = exclude ? remaining.substring(1) : remaining;
      ({String text, KikoSearchSuggestion item})? match;
      for (final alias in aliases) {
        if (candidate.toLowerCase().startsWith(alias.text.toLowerCase()) &&
            !validSelections.any(
              (s) =>
                  s.start > cursor &&
                  s.start < cursor + alias.text.length + (exclude ? 1 : 0),
            ) &&
            (candidate.length == alias.text.length ||
                RegExp(r'\s').hasMatch(candidate[alias.text.length]))) {
          match = alias;
          break;
        }
      }
      if (match != null) {
        parts.add((exclude ? match.item.excluded() : match.item).keyword);
        remaining = candidate.substring(match.text.length);
        cursor += match.text.length + (exclude ? 1 : 0);
      } else {
        final word = RegExp(r'^\S+').firstMatch(remaining)!.group(0)!;
        parts.add(word);
        remaining = remaining.substring(word.length);
        cursor += word.length;
      }
    }
    return KikoSearchQuery(keyword: parts.join(' '), displayText: display);
  }
}
