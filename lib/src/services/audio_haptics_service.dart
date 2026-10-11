import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/audio_track.dart';
import '../utils/local_file_url.dart';
import 'audio_haptic_pattern.dart';
import 'log_service.dart';

final _hapticsLog = LogService.instance;

typedef AudioHapticsPositionProvider = Duration Function();
typedef AudioHapticsPlayingProvider = bool Function();

class AudioHapticsService {
  AudioHapticsService({
    MethodChannel? channel,
    AudioHapticPatternGenerator patternGenerator =
        const AudioHapticPatternGenerator(),
    AudioHapticsPositionProvider? positionProvider,
    AudioHapticsPlayingProvider? playingProvider,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _patternGenerator = patternGenerator,
        _positionProvider = positionProvider,
        _playingProvider = playingProvider {
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  static final AudioHapticsService instance = AudioHapticsService();
  static const String _channelName = 'com.meteor.kikoeruflutter/audio_haptics';

  final MethodChannel _channel;
  final AudioHapticPatternGenerator _patternGenerator;
  AudioHapticsPositionProvider? _positionProvider;
  AudioHapticsPlayingProvider? _playingProvider;

  bool _enabled = false;
  bool _isForegroundActive = true;
  double _intensity = 0.85;
  List<AudioHapticEvent> _events = const [];
  Timer? _timer;
  int _nextEventIndex = 0;
  int _analysisGeneration = 0;
  bool _platformPulseFailureLogged = false;
  bool _timerStartLogged = false;

  bool get enabled => _enabled;
  bool get _supportsPlatform => Platform.isIOS || Platform.isAndroid;

  void attachPlaybackState({
    required AudioHapticsPositionProvider positionProvider,
    required AudioHapticsPlayingProvider playingProvider,
  }) {
    _positionProvider = positionProvider;
    _playingProvider = playingProvider;
  }

  Future<void> updateSettings({
    required bool enabled,
    required double intensity,
  }) async {
    final previousEnabled = _enabled;
    final previousIntensity = _intensity;
    _enabled = enabled && _supportsPlatform;
    _intensity = intensity.clamp(0.2, 1.0);

    if (previousEnabled != _enabled ||
        (previousIntensity - _intensity).abs() > 0.001 ||
        enabled != _enabled) {
      _hapticsLog.info(
        '设置更新: requested=$enabled, effective=$_enabled, '
        'supported=$_supportsPlatform, intensity=${_intensity.toStringAsFixed(2)}, '
        'platform=${Platform.operatingSystem}',
        tag: 'AudioHaptics',
      );
    }

    if (!_enabled) {
      await stop(clearSource: false);
    }
  }

  void setForegroundActive(bool isActive) {
    if (_isForegroundActive == isActive) return;
    _isForegroundActive = isActive;
    _hapticsLog.info(
      '前台状态更新: active=$_isForegroundActive',
      tag: 'AudioHaptics',
    );

    if (!_isForegroundActive) {
      unawaited(pause());
      return;
    }

    if (_enabled && _events.isNotEmpty && (_playingProvider?.call() ?? false)) {
      start();
    }
  }

  Future<void> prepareForTrack(AudioTrack track) async {
    _events = const [];
    _nextEventIndex = 0;
    _analysisGeneration++;
    _resetDiagnosticsForNewAnalysis();

    if (!_enabled) return;

    final path = _localPathFromTrack(track);
    if (path == null) {
      _hapticsLog.captureOutput(
        '[AudioHaptics] 跳过触感分析，仅支持已下载音频: ${track.title}',
      );
      return;
    }

    final generation = _analysisGeneration;

    try {
      _hapticsLog.info(
        '开始完整文件分析: title="${track.title}", path=${_shortPath(path)}, '
        'file=${await _fileState(path)}',
        tag: 'AudioHaptics',
      );
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'analyze',
        {
          'path': path,
          'frameMs': AudioHapticPatternGenerator.defaultFrameMs,
          'maxDurationMs': 3 * 60 * 60 * 1000,
        },
      );
      if (generation != _analysisGeneration || raw == null) return;

      final analysis = AudioHapticAnalysis.fromPlatform(raw);
      _events = _patternGenerator.generate(
        analysis,
        userIntensity: _intensity,
      );
      _nextEventIndex = _indexForPosition(
        _positionProvider?.call() ?? Duration.zero,
      );
      _hapticsLog.info(
        '完整分析完成: title="${track.title}", frames=${analysis.energies.length}, '
        'events=${_events.length}, startIndex=$_nextEventIndex',
        tag: 'AudioHaptics',
      );
      if (_isForegroundActive && (_playingProvider?.call() ?? false)) {
        start();
      }
    } catch (e) {
      if (generation != _analysisGeneration) return;
      _events = const [];
      _hapticsLog.captureOutput('[AudioHaptics] 音频分析失败: $e');
    }
  }

  Future<void> skipForTrack(AudioTrack track) async {
    _events = const [];
    _nextEventIndex = 0;
    _analysisGeneration++;
    _resetDiagnosticsForNewAnalysis();
    if (_enabled) {
      _hapticsLog.captureOutput(
        '[AudioHaptics] 跳过触感分析，仅支持已下载音频: ${track.title}',
      );
    }
    await _silencePlatformHaptics();
  }

  void start() {
    if (!_enabled || !_isForegroundActive || _events.isEmpty) return;
    if (_timer?.isActive ?? false) return;
    _timer?.cancel();
    if (!_timerStartLogged) {
      _hapticsLog.info(
        '触感定时器启动: events=${_events.length}, '
        'position=${(_positionProvider?.call() ?? Duration.zero).inMilliseconds}ms',
        tag: 'AudioHaptics',
      );
      _timerStartLogged = true;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 24), (_) {
      unawaited(_tick());
    });
  }

  Future<void> pause() async {
    _timer?.cancel();
    _timer = null;
    await _silencePlatformHaptics();
  }

  Future<void> stop({bool clearSource = true}) async {
    _timer?.cancel();
    _timer = null;
    _events = const [];
    _nextEventIndex = 0;
    _analysisGeneration++;
    _resetDiagnosticsForNewAnalysis();
    await _stopPlatformHaptics();
  }

  void seek(Duration position) {
    _nextEventIndex = _indexForPosition(position);
  }

  Future<void> _tick() async {
    if (!_enabled || !_isForegroundActive || _events.isEmpty) return;
    final isPlaying = _playingProvider?.call() ?? false;
    if (!isPlaying) return;

    final position = _positionProvider?.call() ?? Duration.zero;
    final positionMs = position.inMilliseconds;
    _nextEventIndex = _nextEventIndex.clamp(0, _events.length);

    while (_nextEventIndex < _events.length &&
        _events[_nextEventIndex].timeMs < positionMs - 90) {
      _nextEventIndex++;
    }

    while (_nextEventIndex < _events.length) {
      final event = _events[_nextEventIndex];
      final delta = event.timeMs - positionMs;
      if (delta > 42) break;

      if (delta >= -80) {
        await _pulse(event);
      }
      _nextEventIndex++;
    }
  }

  Future<void> _pulse(AudioHapticEvent event) async {
    if (!_enabled || !_isForegroundActive) return;
    try {
      await _channel.invokeMethod<void>('pulse', {
        'intensity': event.intensity,
        'durationMs': event.durationMs,
      });
    } catch (e) {
      if (!_platformPulseFailureLogged) {
        _hapticsLog.warning(
          '平台触感脉冲调用失败，后续同一分析周期内不再重复记录: $e',
          tag: 'AudioHaptics',
        );
        _platformPulseFailureLogged = true;
      }
      // Platform haptics are best-effort; never interrupt audio playback.
    }
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'analysisChunk':
        return null;
      case 'analysisFinished':
        return null;
      case 'analysisFailed':
        return null;
      case 'diagnostic':
        _hapticsLog.info(
          _analysisMessage(call.arguments),
          tag: 'AudioHaptics',
        );
        return null;
      default:
        throw MissingPluginException(
            'Unknown audio haptics method: ${call.method}');
    }
  }

  String _analysisMessage(dynamic arguments) {
    if (arguments is Map && arguments['message'] != null) {
      return arguments['message'].toString();
    }
    return arguments.toString();
  }

  int _indexForPosition(Duration position) {
    if (_events.isEmpty) return 0;
    final positionMs = position.inMilliseconds;
    var low = 0;
    var high = _events.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_events[mid].timeMs < positionMs) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  String? _localPathFromTrack(AudioTrack track) {
    final sourcePath = track.sourcePath;
    if (sourcePath != null && sourcePath.isNotEmpty) return sourcePath;

    final localPath = LocalFileUrl.pathFromUrl(track.url);
    return localPath != null && localPath.isNotEmpty ? localPath : null;
  }

  void _resetDiagnosticsForNewAnalysis() {
    _platformPulseFailureLogged = false;
    _timerStartLogged = false;
  }

  String _shortPath(String? path) {
    if (path == null || path.isEmpty) return 'none';
    if (path.length <= 96) return path;
    return '...${path.substring(path.length - 96)}';
  }

  Future<String> _fileState(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 'missing';
      final length = await file.length();
      return 'exists:${length}B';
    } catch (e) {
      return 'error:$e';
    }
  }

  Future<void> _stopPlatformHaptics() async {
    if (!_supportsPlatform) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // Platform haptics are optional and should never affect playback.
    }
  }

  Future<void> _silencePlatformHaptics() async {
    if (!_supportsPlatform) return;
    try {
      await _channel.invokeMethod<void>('silence');
    } catch (_) {
      // Platform haptics are optional and should never affect playback.
    }
  }
}
