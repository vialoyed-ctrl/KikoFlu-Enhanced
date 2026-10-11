import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/audio_effect_settings.dart';

void main() {
  test('invalid persisted values normalize before reaching native audio', () {
    final s = AudioEffectSettings.fromJson({
      'enabled': true,
      'width': 99,
      'preamp': -99,
      'bands': [
        {'frequency': 0, 'gain': 99, 'q': 0},
      ],
    });
    expect(s.width, 2);
    expect(s.preamp, -12);
    expect(s.bands.length, 10);
    expect(s.bands.first.frequency, 20);
    expect(s.bands.first.gain, 12);
    expect(s.bands.first.q, 0.2);
  });
  test('reference preset persists screenshot curve, gain and stereo', () {
    final s = AudioEffectSettings.reference();
    final restored = AudioEffectSettings.fromJson(s.toJson());
    expect(restored.enabled, true);
    expect(restored.width, 1.5);
    expect(restored.preamp, 7.2);
    expect(restored.bands[6].gain, 6);
    expect(restored.bands[9].frequency, 16000);
    expect(restored.bands[9].gain, 3);
    expect(restored.bands[0].q, 1.5);
  });
}
