double _bounded(Object? value, double fallback, double min, double max) {
  final n = value is num ? value.toDouble() : fallback;
  return (n.isFinite ? n : fallback).clamp(min, max).toDouble();
}

class EqBand {
  final int type;
  final double frequency, gain, q;
  const EqBand({
    this.type = 0,
    required this.frequency,
    this.gain = 0,
    this.q = 1.5,
  });
  factory EqBand.fromJson(Map<String, dynamic> json, double fallback) => EqBand(
    type: _bounded(json['type'], 0, 0, 2).round(),
    frequency: _bounded(json['frequency'], fallback, 20, 20000),
    gain: _bounded(json['gain'], 0, -12, 12),
    q: _bounded(json['q'], 1.5, .2, 10),
  );
  Map<String, dynamic> toJson() => {
    'type': type,
    'frequency': frequency,
    'gain': gain,
    'q': q,
  };
  EqBand copyWith({int? type, double? frequency, double? gain, double? q}) =>
      EqBand.fromJson({
        'type': type ?? this.type,
        'frequency': frequency ?? this.frequency,
        'gain': gain ?? this.gain,
        'q': q ?? this.q,
      }, this.frequency);
}

class AudioEffectSettings {
  static const frequencies = <double>[
    31,
    62,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];
  final bool enabled;
  final double preamp, width;
  final List<EqBand> bands;
  AudioEffectSettings({
    required this.enabled,
    required this.preamp,
    required this.width,
    required List<EqBand> bands,
  }) : bands = List.unmodifiable(bands);
  // Poweramp screenshot: +7.2 dB gain, ten-band curve, 50% expansion.
  factory AudioEffectSettings.reference() {
    const gains = [-2.9, -2.9, 2.5, 3.6, 4.8, 4.7, 6.0, 6.0, 3.0, 3.0];
    return AudioEffectSettings(
      enabled: true,
      preamp: 7.2,
      width: 1.5,
      bands: List.generate(
        10,
        (i) => EqBand(frequency: frequencies[i], gain: gains[i]),
      ),
    );
  }
  factory AudioEffectSettings.original() => AudioEffectSettings(
    enabled: false,
    preamp: 0,
    width: 1,
    bands: frequencies.map((f) => EqBand(frequency: f)).toList(),
  );
  factory AudioEffectSettings.asmr() => AudioEffectSettings(
    enabled: true,
    preamp: -2,
    width: 1,
    bands: List.generate(
      10,
      (i) => EqBand(
        frequency: frequencies[i],
        gain: const [-2.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.5, 0.5, -0.5, 0.0][i],
      ),
    ),
  );
  factory AudioEffectSettings.fromJson(Map<String, dynamic> json) {
    final fallback = AudioEffectSettings.reference();
    final raw = json['bands'] is List ? json['bands'] as List : const [];
    return AudioEffectSettings(
      enabled: json['enabled'] is bool
          ? json['enabled'] as bool
          : fallback.enabled,
      preamp: _bounded(json['preamp'], fallback.preamp, -12, 12),
      width: _bounded(json['width'], fallback.width, 0, 2),
      bands: List.generate(
        10,
        (i) => i < raw.length && raw[i] is Map
            ? EqBand.fromJson(
                Map<String, dynamic>.from(raw[i] as Map),
                frequencies[i],
              )
            : fallback.bands[i],
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'preamp': preamp,
    'width': width,
    'bands': bands.map((b) => b.toJson()).toList(),
  };
  AudioEffectSettings copyWith({
    bool? enabled,
    double? preamp,
    double? width,
    List<EqBand>? bands,
  }) => AudioEffectSettings.fromJson({
    'enabled': enabled ?? this.enabled,
    'preamp': preamp ?? this.preamp,
    'width': width ?? this.width,
    'bands': (bands ?? this.bands).map((b) => b.toJson()).toList(),
  });
}
