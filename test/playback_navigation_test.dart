import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/playback_navigation_settings.dart';
import 'package:kikoeru_flutter/src/services/playback_navigation.dart';

Duration s(int n) => Duration(seconds: n);
void main() {
  test('independent time settings and mode round trip', () {
    const settings = PlaybackNavigationSettings(
      backwardSeconds: 5,
      forwardSeconds: 30,
      mode: MediaNavigationMode.subtitle,
    );
    final restored = PlaybackNavigationSettings.fromJson(settings.toJson());
    expect(restored.backwardSeconds, 5);
    expect(restored.forwardSeconds, 30);
    expect(restored.mode, MediaNavigationMode.subtitle);
    expect(const PlaybackNavigationSettings().backwardSeconds, 10);
  });
  test('corrupt saved settings normalize to safe defaults', () {
    final value = PlaybackNavigationSettings.fromJson({
      'backwardSeconds': -5,
      'forwardSeconds': 50000,
      'mode': 'bad',
    });
    expect(value.backwardSeconds, 10);
    expect(value.forwardSeconds, 10);
    expect(value.mode, MediaNavigationMode.time);
  });
  test('time jumps independently and clamp at file boundaries', () {
    const settings = PlaybackNavigationSettings(
      backwardSeconds: 5,
      forwardSeconds: 30,
    );
    expect(PlaybackNavigation.target(s(20), s(60), false, settings, []), s(15));
    expect(PlaybackNavigation.target(s(20), s(60), true, settings, []), s(50));
    expect(PlaybackNavigation.target(s(2), s(60), false, settings, []), s(0));
    expect(PlaybackNavigation.target(s(55), s(60), true, settings, []), s(60));
    expect(PlaybackNavigation.target(s(20), null, true, settings, []), s(50));
  });
  test(
    'subtitle previous moves to previous segment even from mid sentence',
    () {
      const settings = PlaybackNavigationSettings(
        mode: MediaNavigationMode.subtitle,
      );
      final cues = [s(0), s(10), s(25), s(40)];
      expect(
        PlaybackNavigation.target(s(17), s(60), false, settings, cues),
        s(0),
      );
      expect(
        PlaybackNavigation.target(s(17), s(60), true, settings, cues),
        s(25),
      );
      expect(
        PlaybackNavigation.target(s(25), s(60), false, settings, cues),
        s(10),
      );
      expect(
        PlaybackNavigation.target(s(25), s(60), true, settings, cues),
        s(40),
      );
    },
  );
  test('subtitle first and last remain within current track', () {
    const settings = PlaybackNavigationSettings(
      mode: MediaNavigationMode.subtitle,
    );
    final cues = [s(5), s(15)];
    expect(PlaybackNavigation.target(s(2), s(60), true, settings, cues), s(5));
    expect(PlaybackNavigation.target(s(2), s(60), false, settings, cues), s(0));
    expect(
      PlaybackNavigation.target(s(20), s(60), true, settings, cues),
      s(20),
    );
  });
  test('offset timestamps, duplicates and invalid cues are handled', () {
    const settings = PlaybackNavigationSettings(
      mode: MediaNavigationMode.subtitle,
    );
    expect(
      PlaybackNavigation.target(s(7), s(60), true, settings, [
        s(18),
        s(-1),
        s(8),
        s(8),
        s(99),
      ]),
      s(8),
    );
    expect(
      PlaybackNavigation.target(s(8), s(60), true, settings, [
        s(18),
        s(8),
        s(8),
      ]),
      s(18),
    );
  });
  test('no usable subtitles falls back to independent time settings', () {
    const settings = PlaybackNavigationSettings(
      mode: MediaNavigationMode.subtitle,
      backwardSeconds: 5,
      forwardSeconds: 15,
    );
    expect(PlaybackNavigation.target(s(20), s(60), true, settings, []), s(35));
    expect(
      PlaybackNavigation.target(s(20), s(60), false, settings, [s(80)]),
      s(15),
    );
  });
}
