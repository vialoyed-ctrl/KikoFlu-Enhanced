import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/kiko_search.dart';
import 'package:kikoeru_flutter/src/models/search_type.dart';

void main() {
  const catalog = KikoSearchCatalog([
    KikoSearchSuggestion(type: SearchType.tag, id: 497, name: 'ASMR'),
    KikoSearchSuggestion(
      type: SearchType.tag,
      id: 999999,
      name: 'Healing',
      translatedName: '治愈',
    ),
    KikoSearchSuggestion(type: SearchType.va, id: 'va-1', name: 'Voice Name'),
  ]);
  test('direct search preserves keywords and recognizes an RJ number', () {
    expect(catalog.compile('rain', const Locale('en')).keyword, 'rain');
    expect(
      catalog.compile('01254431', const Locale('zh')).keyword,
      'RJ01254431',
    );
  });
  test(
    'translated pasted tags use original metadata and retain exclusions',
    () {
      expect(
        catalog.compile('ASMR -治愈 rain', const Locale('zh')).keyword,
        r'$tag:ASMR$ $-tag:Healing$ rain',
      );
      expect(
        catalog.compile('Voice Name', const Locale('en')).keyword,
        r'$va:Voice Name$',
      );
    },
  );
  test('autocomplete offers include and exclude variants across types', () {
    final suggestions = catalog.suggest('AS', const Locale('en'));
    expect(suggestions.map((s) => s.display(const Locale('en'))), [
      'ASMR',
      '-ASMR',
    ]);
    expect(catalog.suggest('-AS', const Locale('en')).single.exclude, isTrue);
  });
  test(
    'autocomplete prioritizes prefix matches over incidental substrings',
    () {
      const catalog = KikoSearchCatalog([
        KikoSearchSuggestion(type: SearchType.circle, id: 3, name: 'BLAST'),
        KikoSearchSuggestion(type: SearchType.tag, id: 497, name: 'ASMR'),
      ]);
      expect(catalog.suggest('AS', const Locale('en')).first.name, 'ASMR');
    },
  );
  test('selecting another suggestion retains earlier search terms', () {
    expect(
      catalog.complete('ASMR He', catalog.items[1], const Locale('zh')),
      'ASMR 治愈',
    );
  });
  test('multiword completion replaces the whole partial name', () {
    expect(
      catalog.complete('rain Voice Na', catalog.items[2], const Locale('en')),
      'rain Voice Name',
    );
  });
  test(
    'an alias cannot absorb an explicitly selected token after a prefix edit',
    () {
      const voice = KikoSearchSuggestion(
        type: SearchType.va,
        id: 'v',
        name: 'Name',
      );
      const overlapping = KikoSearchCatalog([
        KikoSearchSuggestion(type: SearchType.tag, id: 5, name: 'Voice Name'),
        voice,
      ]);
      expect(
        overlapping
            .compile(
              'Voice Name',
              const Locale('en'),
              selections: const [KikoSearchSelection(6, 10, voice)],
            )
            .keyword,
        r'Voice $va:Name$',
      );
    },
  );
}
