String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

String formatDuration(Duration duration, {bool padHours = true}) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    final hourText = padHours ? hours.toString().padLeft(2, '0') : '$hours';
    return '$hourText:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

String formatDurationSeconds(dynamic secondsValue, {bool padHours = true}) {
  final seconds = secondsValue is num ? secondsValue.toInt() : null;
  if (seconds == null || seconds <= 0) return '';

  return formatDuration(Duration(seconds: seconds), padHours: padHours);
}

String formatRJCode(int id) {
  String code = id.toString();
  if (code.length == 5) {
    code = '0$code';
  } else if (code.length == 7) {
    code = '0$code';
  }
  return 'RJ$code';
}
