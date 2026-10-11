import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_effect_settings.dart';

class AudioEffectNotifier extends StateNotifier<AudioEffectSettings> {
  static const preferenceKey = 'audio_effects_v1';
  late final Future<void> ready;
  bool _changed = false;
  Future<void> _write = Future.value();
  AudioEffectNotifier() : super(AudioEffectSettings.reference()) {
    ready = _load();
  }
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(preferenceKey);
      if (!mounted || _changed || raw == null) return;
      state = AudioEffectSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      /* Keep defaults if a saved setting cannot be read. */
    }
  }

  Future<void> update(AudioEffectSettings value) {
    _changed = true;
    state = AudioEffectSettings.fromJson(value.toJson());
    final encoded = jsonEncode(state.toJson());
    _write = _write
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(preferenceKey, encoded);
        })
        .catchError((Object _) {});
    return _write;
  }
}

final audioEffectProvider =
    StateNotifierProvider<AudioEffectNotifier, AudioEffectSettings>(
      (ref) => AudioEffectNotifier(),
    );
