import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/audio_haptic_pattern.dart';

void main() {
  group('AudioHapticPatternGenerator', () {
    test('returns no events for silence', () {
      const generator = AudioHapticPatternGenerator();
      final events = generator.generate(
        const AudioHapticAnalysis(
          frameMs: 50,
          energies: [0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      expect(events, isEmpty);
    });

    test('detects transient spikes and respects minimum spacing', () {
      const generator = AudioHapticPatternGenerator();
      final events = generator.generate(
        const AudioHapticAnalysis(
          frameMs: 50,
          energies: [
            0.01,
            0.01,
            0.02,
            0.86,
            0.12,
            0.08,
            0.02,
            0.9,
            0.13,
            0.02,
          ],
        ),
      );

      expect(events, isNotEmpty);
      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].timeMs - events[i - 1].timeMs,
          greaterThanOrEqualTo(AudioHapticPatternGenerator.minEventIntervalMs),
        );
      }
    });
  });
}
