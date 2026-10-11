enum VideoGestureAction { none, seek, brightness, volume }

class VideoGesturePolicy {
  static VideoGestureAction action({
    required double dx,
    required double dy,
    required bool left,
  }) {
    if (dx.abs() < 12 && dy.abs() < 12) return VideoGestureAction.none;
    if (dx.abs() > dy.abs()) return VideoGestureAction.seek;
    return left ? VideoGestureAction.brightness : VideoGestureAction.volume;
  }

  static Duration seek({
    required Duration origin,
    required double dx,
    required double width,
    required Duration duration,
  }) {
    if (width <= 0 || duration <= Duration.zero) return origin;
    final milliseconds =
        (origin.inMilliseconds + dx / width * duration.inMilliseconds).round();
    return Duration(
      milliseconds: milliseconds.clamp(0, duration.inMilliseconds),
    );
  }

  static double level({
    required double origin,
    required double dy,
    required double height,
  }) => height <= 0 ? origin : (origin - dy / height).clamp(0.0, 1.0);
}
