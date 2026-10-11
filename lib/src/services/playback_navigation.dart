import '../models/playback_navigation_settings.dart';

class PlaybackNavigation {
  static Duration target(
    Duration position,
    Duration? duration,
    bool forward,
    PlaybackNavigationSettings settings,
    List<Duration> subtitleStarts,
  ) {
    Duration clamp(Duration value) {
      if (value < Duration.zero) return Duration.zero;
      if (duration != null && value > duration) return duration;
      return value;
    }

    if (settings.mode == MediaNavigationMode.subtitle) {
      final starts =
          subtitleStarts
              .where(
                (t) => t >= Duration.zero && (duration == null || t < duration),
              )
              .toSet()
              .toList()
            ..sort();
      if (starts.isNotEmpty) {
        if (forward) {
          for (final start in starts) {
            if (start > position) return start;
          }
          return clamp(position);
        }
        // Find the active (or most recent) segment, then go one segment back.
        var current = -1;
        for (var i = 0; i < starts.length && starts[i] <= position; i++) {
          current = i;
        }
        return current > 0 ? starts[current - 1] : Duration.zero;
      }
    }
    return clamp(
      position +
          Duration(
            seconds: forward
                ? settings.forwardSeconds
                : -settings.backwardSeconds,
          ),
    );
  }
}
