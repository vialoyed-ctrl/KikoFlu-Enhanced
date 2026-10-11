enum MediaNavigationMode { time, subtitle }

class PlaybackNavigationSettings {
  const PlaybackNavigationSettings({
    this.backwardSeconds = 10,
    this.forwardSeconds = 10,
    this.mode = MediaNavigationMode.time,
  });
  final int backwardSeconds;
  final int forwardSeconds;
  final MediaNavigationMode mode;
  static const maxSeconds = 600;

  factory PlaybackNavigationSettings.fromJson(Map<String, dynamic> json) {
    int seconds(Object? value) =>
        value is int && value >= 1 && value <= maxSeconds ? value : 10;
    return PlaybackNavigationSettings(
      backwardSeconds: seconds(json['backwardSeconds']),
      forwardSeconds: seconds(json['forwardSeconds']),
      mode: json['mode'] == 'subtitle'
          ? MediaNavigationMode.subtitle
          : MediaNavigationMode.time,
    );
  }
  Map<String, dynamic> toJson() => {
    'backwardSeconds': backwardSeconds,
    'forwardSeconds': forwardSeconds,
    'mode': mode.name,
  };
}
