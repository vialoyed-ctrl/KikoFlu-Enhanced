import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_rules.dart';

void main() {
  group('文件夹名称模式匹配测试', () {
    test('RJ格式匹配测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ1234567'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ12345678'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('rj123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('Rj123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ12345'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ123456789'), false);
    });

    test('BJ格式匹配测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName('BJ123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('bj1234567'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('BJ12345678'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('Bj12345'), false);
    });

    test('VJ格式匹配测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName('VJ123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('vj1234567'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('VJ12345678'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('vJ12345'), false);
    });

    test('纯数字格式匹配测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName('123456'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('1234567'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('12345678'), true);
      expect(SubtitleLibraryRules.matchesWorkFolderName('12345'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('123456789'), false);
    });

    test('不匹配的格式测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ12345a'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('123456a'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('ABC123456'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('R123456'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ 123456'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ-123456'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('Season 1'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('未知作品'), false);
    });

    test('边界情况测试', () {
      expect(SubtitleLibraryRules.matchesWorkFolderName(''), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('RJ'), false);
      expect(SubtitleLibraryRules.matchesWorkFolderName('123'), false);
    });

    test('实际场景测试 - 多层嵌套', () {
      // 模拟实际场景：压缩包或文件夹中可能包含多个符合规则的子目录
      final testCases = {
        'RJ123456': true, // 应该放入"已解析"
        'RJ234567': true, // 应该放入"已解析"
        'BJ345678': true, // 应该放入"已解析"
        'VJ456789': true, // 应该放入"已解析"
        '12345678': true, // 应该放入"已解析"
        'MyMusic': false, // 应该放入"未知作品"（如果有字幕文件）
        'Collection': false, // 应该放入"未知作品"（如果有字幕文件）
        'Audio': false, // 应该放入"未知作品"（如果有字幕文件）
      };

      testCases.forEach((folderName, shouldMatch) {
        expect(
            SubtitleLibraryRules.matchesWorkFolderName(folderName), shouldMatch,
            reason:
                '$folderName should ${shouldMatch ? "match" : "not match"}');
      });
    });

    test('标准化作品文件夹名', () {
      expect(
        SubtitleLibraryRules.normalizeWorkFolderName('123456'),
        'RJ123456',
      );
      expect(
        SubtitleLibraryRules.normalizeWorkFolderName('rj123456'),
        'RJ123456',
      );
      expect(
        SubtitleLibraryRules.normalizeWorkFolderName('Bj1234567'),
        'BJ1234567',
      );
      expect(
        SubtitleLibraryRules.normalizeWorkFolderName('Audio'),
        'Audio',
      );
    });
  });
}
