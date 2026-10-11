import 'dart:math' as math;

class AudioHapticAnalysis {
  const AudioHapticAnalysis({
    required this.frameMs,
    required this.energies,
    this.startFrame = 0,
    this.durationMs,
  });

  final int frameMs;
  final List<double> energies;
  final int startFrame;
  final int? durationMs;

  factory AudioHapticAnalysis.fromPlatform(Map<dynamic, dynamic> value) {
    final frameMs = (value['frameMs'] as num?)?.toInt() ?? 50;
    final startFrame = (value['startFrame'] as num?)?.toInt() ?? 0;
    final durationMs = (value['durationMs'] as num?)?.toInt();
    final rawEnergies = value['energies'];
    final energies = rawEnergies is List
        ? rawEnergies
            .map((item) => item is num ? item.toDouble() : 0.0)
            .toList(growable: false)
        : const <double>[];

    return AudioHapticAnalysis(
      frameMs: frameMs.clamp(20, 200),
      energies: energies,
      startFrame: math.max(0, startFrame),
      durationMs: durationMs,
    );
  }
}

class AudioHapticEvent {
  const AudioHapticEvent({
    required this.timeMs,
    required this.intensity,
    required this.durationMs,
  });

  final int timeMs;
  final double intensity;
  final int durationMs;

  @override
  String toString() {
    return 'AudioHapticEvent(timeMs: $timeMs, intensity: $intensity, '
        'durationMs: $durationMs)';
  }
}

class AudioHapticPatternGenerator {
  const AudioHapticPatternGenerator();

  static const int defaultFrameMs = 50;
  static const int minEventIntervalMs = 90;
  static const int sustainIntervalMs = 260;
  static const int maxEvents = 24000;

  List<AudioHapticEvent> generate(
    AudioHapticAnalysis analysis, {
    double userIntensity = 1.0,
  }) {
    final energies = analysis.energies
        .map((value) => value.isFinite ? value.clamp(0.0, 1.0) : 0.0)
        .toList(growable: false);
    if (energies.length < 4) return const [];

    final frameMs = analysis.frameMs <= 0 ? defaultFrameMs : analysis.frameMs;
    final compressed = energies
        .map((value) => math.log(1 + value * 24) / math.log(25))
        .toList(growable: false);

    final stats = _robustStats(compressed);
    final noiseFloor = stats.median;
    final activeThreshold = (noiseFloor + stats.mad * 2.6).clamp(0.08, 0.72);
    final onsetThreshold = (stats.mad * 1.7).clamp(0.025, 0.18);

    final events = <AudioHapticEvent>[];
    var fast = compressed.first;
    var slow = compressed.first;
    var previous = compressed.first;
    var lastEventMs = -minEventIntervalMs;
    var lastSustainMs = -sustainIntervalMs;

    for (var i = 1; i < compressed.length; i++) {
      final energy = compressed[i];
      fast = fast * 0.45 + energy * 0.55;
      slow = slow * 0.92 + energy * 0.08;

      final onset = (fast - slow).clamp(0.0, 1.0);
      final rise = (energy - previous).clamp(0.0, 1.0);
      previous = energy;

      final timeMs = i * frameMs;
      final canFire = timeMs - lastEventMs >= minEventIntervalMs;
      final isTransient = energy >= activeThreshold &&
          onset + rise * 0.55 >= onsetThreshold &&
          canFire;

      if (isTransient) {
        final intensity = _eventIntensity(
          energy: energy,
          onset: onset,
          rise: rise,
          userIntensity: userIntensity,
        );
        events.add(AudioHapticEvent(
          timeMs: timeMs,
          intensity: intensity,
          durationMs: _eventDuration(intensity),
        ));
        lastEventMs = timeMs;
        lastSustainMs = timeMs;
      } else if (energy >= activeThreshold + 0.14 &&
          timeMs - lastSustainMs >= sustainIntervalMs &&
          timeMs - lastEventMs >= minEventIntervalMs) {
        final intensity =
            (0.22 + (energy - activeThreshold) * 0.65).clamp(0.18, 0.72) *
                userIntensity.clamp(0.2, 1.4);
        events.add(AudioHapticEvent(
          timeMs: timeMs,
          intensity: intensity.clamp(0.12, 1.0),
          durationMs: 38,
        ));
        lastEventMs = timeMs;
        lastSustainMs = timeMs;
      }

      if (events.length >= maxEvents) break;
    }

    return events;
  }

  static _RobustStats _robustStats(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final median = _median(sorted);
    final deviations = values
        .map((value) => (value - median).abs())
        .toList(growable: false)
      ..sort();
    return _RobustStats(
      median: median,
      mad: math.max(_median(deviations), 0.0001),
    );
  }

  static double _median(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0;
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) return sortedValues[middle];
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  static double _eventIntensity({
    required double energy,
    required double onset,
    required double rise,
    required double userIntensity,
  }) {
    final raw = 0.18 + energy * 0.45 + onset * 1.9 + rise * 0.85;
    return (raw * userIntensity.clamp(0.2, 1.4)).clamp(0.12, 1.0);
  }

  static int _eventDuration(double intensity) {
    if (intensity >= 0.82) return 58;
    if (intensity >= 0.55) return 46;
    return 32;
  }
}

class _RobustStats {
  const _RobustStats({
    required this.median,
    required this.mad,
  });

  final double median;
  final double mad;
}
