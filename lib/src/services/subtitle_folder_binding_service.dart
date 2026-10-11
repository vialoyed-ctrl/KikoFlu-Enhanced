import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_track.dart';
import 'subtitle_database.dart';
import 'subtitle_library_service.dart';
import 'subtitle_folder_matching.dart';

class SubtitleFolderBindingService {
  static int? workId(AudioTrack track) =>
      track.workId ??
      SubtitleFolderMatcher.workNumber(
        '${track.sourcePath ?? ''} ${track.album ?? ''} ${track.title} ${track.url}',
      );
  static String? _key(AudioTrack track) {
    final id = workId(track);
    return id == null ? null : 'subtitle_folder_binding_v1_$id';
  }

  static Future<Map<String, dynamic>> _read(AudioTrack track) async {
    final key = _key(track);
    final raw = key == null
        ? null
        : (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {'folder': raw};
    }
  }

  static Future<String?> binding(AudioTrack track) async =>
      (await _read(track))['folder'] as String?;

  static Future<String?> selectedFile(AudioTrack track) async {
    final data = await _read(track);
    final files = data['files'];
    return files is Map ? files[track.title] as String? : null;
  }

  static Future<void> bind(
    AudioTrack track,
    String? folder, {
    String? file,
  }) async {
    final key = _key(track);
    if (key == null) throw StateError('当前音频缺少作品号，无法保存作品匹配');
    final prefs = await SharedPreferences.getInstance();
    final old = await _read(track);
    final files = old['folder'] == folder && old['files'] is Map
        ? Map<String, dynamic>.from(old['files'] as Map)
        : <String, dynamic>{};
    if (file != null) files[track.title] = file;
    final ok = folder == null
        ? await prefs.remove(key)
        : await prefs.setString(
            key,
            jsonEncode({'folder': folder, 'files': files}),
          );
    if (!ok) throw StateError('保存字幕匹配失败');
  }

  static Future<List<String>> folders() async {
    await SubtitleLibraryService.ensureInitialized();
    final db = await SubtitleDatabase.instance.database;
    // Only fetch distinct directory names, not the whole subtitle library.
    final rows = await db.rawQuery(
      "SELECT DISTINCT category || '/' || CASE WHEN INSTR(SUBSTR(relative_path, LENGTH(category) + 2), '/') > 0 THEN SUBSTR(SUBSTR(relative_path, LENGTH(category) + 2), 1, INSTR(SUBSTR(relative_path, LENGTH(category) + 2), '/') - 1) ELSE '' END AS folder FROM subtitle_files ORDER BY folder",
    );
    return rows
        .map((r) => (r['folder'] as String).replaceFirst(RegExp(r'/$'), ''))
        .toList();
  }

  static Future<List<String>> files(String folder) async {
    await SubtitleLibraryService.ensureInitialized();
    final db = await SubtitleDatabase.instance.database;
    // Prefix comparison rather than LIKE: folder names may contain % or _.
    final prefix = '$folder/';
    final rows = await db.query(
      'subtitle_files',
      columns: ['relative_path'],
      where: 'substr(relative_path, 1, length(?)) = ?',
      whereArgs: [prefix, prefix],
    );
    return rows
        .map((r) => r['relative_path'] as String)
        .where(SubtitleFolderMatcher.supported)
        .toList();
  }

  static Future<String?> resolve(AudioTrack track) async {
    await SubtitleLibraryService.ensureInitialized();
    final saved = await binding(track);
    final List<String> candidates;
    if (saved != null) {
      candidates = await files(saved);
    } else {
      final id = workId(track);
      if (id == null) return null;
      final records = await SubtitleDatabase.instance.getFilesByWorkId(id);
      candidates = records.map((r) => r.relativePath).toList();
    }
    final explicit = saved == null ? null : await selectedFile(track);
    final relative = explicit != null && candidates.contains(explicit)
        ? explicit
        : SubtitleFolderMatcher.select(track.title, candidates);
    if (relative == null) return null;
    final root = await SubtitleLibraryService.getSubtitleLibraryDirectory();
    final absolute = p.joinAll([root.path, ...relative.split('/')]);
    return await File(absolute).exists() ? absolute : null;
  }
}
