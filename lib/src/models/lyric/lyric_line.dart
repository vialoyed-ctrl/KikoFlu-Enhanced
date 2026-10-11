class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  LyricLine copyWith({
    Duration? startTime,
    Duration? endTime,
    String? text,
  }) {
    return LyricLine(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
    );
  }

  /// 应用时间轴偏移
  LyricLine applyOffset(Duration offset) {
    return LyricLine(
      startTime: startTime + offset,
      endTime: endTime + offset,
      text: text,
    );
  }
}
