import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/src/providers/search_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a tag search immediately after startup preserves existing history and its typed parameters',
    () async {
      SharedPreferences.setMockInitialValues({
        'search_history': jsonEncode([
          SearchHistoryItem(
            id: 'old',
            keyword: 'rain',
            displayText: 'rain',
            timestamp: DateTime(2026),
          ).toJson(),
        ]),
      });
      final notifier = SearchHistoryNotifier();
      addTearDown(notifier.dispose);
      await notifier.addHistory(
        keyword: r'$tag:Healing$',
        displayText: '治愈',
        searchParams: {'displayKeyword': '治愈', 'useKeywordSearch': true},
      );
      expect(notifier.state.items.map((item) => item.keyword), [
        r'$tag:Healing$',
        'rain',
      ]);
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('search_history')!) as List;
      expect(stored.first['displayText'], '治愈');
      expect(stored.first['searchParams']['useKeywordSearch'], true);
      await notifier.addHistory(keyword: r'$tag:Healing$', displayText: '治愈');
      expect(notifier.state.items.length, 2);
    },
  );
}
