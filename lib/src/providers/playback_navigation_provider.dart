import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playback_navigation_settings.dart';

class PlaybackNavigationNotifier
    extends StateNotifier<PlaybackNavigationSettings> {
  PlaybackNavigationNotifier() : super(const PlaybackNavigationSettings()) {
    ready = _load();
  }
  static const preferenceKey = 'playback_navigation_v1';
  late final Future<void> ready;
  bool _changed = false;
  Future<void> _write = Future.value();
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(preferenceKey);
      if (mounted && !_changed && raw != null) {
        state = PlaybackNavigationSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {
      /* Corrupt preferences keep defaults. */
    }
  }

  Future<void> update(PlaybackNavigationSettings settings) {
    _changed = true;
    state = PlaybackNavigationSettings.fromJson(settings.toJson());
    final encoded = jsonEncode(state.toJson());
    _write = _write.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(preferenceKey, encoded)) {
        throw StateError('无法保存跳转设置');
      }
    });
    // Keep later saves usable even if this one failed; callers still see error.
    final result = _write;
    _write = result.catchError((Object _) {});
    return result;
  }
}

final playbackNavigationProvider =
    StateNotifierProvider<
      PlaybackNavigationNotifier,
      PlaybackNavigationSettings
    >((ref) => PlaybackNavigationNotifier());
