import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../models/audio_track.dart';
import '../../providers/lyric_provider.dart';
import '../../services/video_display_service.dart';
import '../../services/video_gesture_policy.dart';

/// A frame of the existing player. Fullscreen changes only its presentation.
class VideoFrame extends StatelessWidget {
  const VideoFrame({
    super.key,
    required this.status,
    this.subtitle = '',
    this.subtitleBottom = 18,
  });
  final Map<String, dynamic> status;
  final String subtitle;
  final double subtitleBottom;
  double get aspectRatio {
    final w = (status['width'] as num?)?.toDouble() ?? 0;
    final h = (status['height'] as num?)?.toDouble() ?? 0;
    final pixel = (status['pixelRatio'] as num?)?.toDouble() ?? 1;
    return w > 0 && h > 0 && pixel > 0 ? w * pixel / h : 16 / 9;
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: status['textureId'] is int
                ? Texture(textureId: status['textureId'] as int)
                : const SizedBox.expand(),
          ),
        ),
        if (status['firstFrame'] != true)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (subtitle.isNotEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: subtitleBottom,
            child: IgnorePointer(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(-1, -1),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class VideoPlayerView extends ConsumerStatefulWidget {
  const VideoPlayerView({super.key, this.fullscreen = false});
  final bool fullscreen;
  static Future<void> openFullscreen(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            backgroundColor: Colors.black,
            body: VideoPlayerView(fullscreen: true),
          ),
        ),
      );
  @override
  ConsumerState<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends ConsumerState<VideoPlayerView> {
  Map<String, dynamic> status = {};
  Timer? poll;
  Timer? hideTimer;
  bool polling = false;
  bool controls = true;
  String? error;
  String? hint;
  Offset origin = Offset.zero;
  double brightness = 0.5;
  double initialBrightness = 0.5;
  double initialVolume = 1;
  Duration initialPosition = Duration.zero;
  Duration? preview;
  VideoGestureAction action = VideoGestureAction.none;
  bool doubleForward = true;
  AudioTrack? gestureTrack;
  bool closing = false;

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(milliseconds: 250), (_) => refresh());
    refresh();
    if (widget.fullscreen) {
      enterFullscreen();
      scheduleHide();
    }
  }

  Future<void> enterFullscreen() async {
    try {
      brightness = await VideoDisplayService.begin();
      if (!mounted) {
        await VideoDisplayService.end();
        return;
      }
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      if (mounted) setState(() => error = '全屏设置失败：$e');
    }
  }

  @override
  void dispose() {
    poll?.cancel();
    hideTimer?.cancel();
    if (widget.fullscreen) {
      unawaited(VideoDisplayService.end().catchError((Object _) {}));
      unawaited(SystemChrome.setPreferredOrientations([]));
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  Future<void> refresh() async {
    if (polling || !mounted) return;
    polling = true;
    try {
      final service = ref.read(audioPlayerServiceProvider);
      final requestedTrack = service.currentTrack;
      final next = await service.getVideoStatus();
      if (mounted && service.currentTrack == requestedTrack) {
        setState(() {
          status = next;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '视频画面加载失败，请重新播放');
    } finally {
      polling = false;
    }
  }

  void scheduleHide() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && preview == null) {
        setState(() {
          controls = false;
          hint = null;
        });
      }
    });
  }

  void toggleControls() {
    setState(() => controls = !controls);
    if (controls) scheduleHide();
  }

  Future<void> navigate() async {
    final service = ref.read(audioPlayerServiceProvider);
    final requestedTrack = service.currentTrack;
    final before = service.position;
    try {
      await service.handleMediaNavigation(doubleForward);
    } catch (_) {
      if (mounted) setState(() => hint = '跳转失败，请重试');
      scheduleHide();
      return;
    }
    if (!mounted || service.currentTrack != requestedTrack) return;
    final delta = (service.position - before).inMilliseconds.abs() / 1000;
    setState(() {
      hint = '${doubleForward ? '快进' : '快退'} ${delta.toStringAsFixed(1)} 秒';
    });
    scheduleHide();
  }

  void startGesture(DragStartDetails details) {
    origin = details.localPosition;
    action = VideoGestureAction.none;
    final service = ref.read(audioPlayerServiceProvider);
    gestureTrack = service.currentTrack;
    initialPosition = service.position;
    initialVolume = ref.read(audioPlayerControllerProvider).volume;
    initialBrightness = brightness;
    hideTimer?.cancel();
  }

  void updateGesture(DragUpdateDetails details, Size size) {
    if (gestureTrack != ref.read(audioPlayerServiceProvider).currentTrack) {
      setState(() {
        preview = null;
        action = VideoGestureAction.none;
      });
      return;
    }
    final dx = details.localPosition.dx - origin.dx;
    final dy = details.localPosition.dy - origin.dy;
    if (action == VideoGestureAction.none) {
      action = VideoGesturePolicy.action(
        dx: dx,
        dy: dy,
        left: origin.dx < size.width / 2,
      );
    }
    final service = ref.read(audioPlayerServiceProvider);
    switch (action) {
      case VideoGestureAction.none:
        return;
      case VideoGestureAction.seek:
        final duration = service.duration;
        if (duration == null) return;
        preview = VideoGesturePolicy.seek(
          origin: initialPosition,
          dx: dx,
          width: size.width,
          duration: duration,
        );
        hint = '${time(preview!)} / ${time(duration)}';
        break;
      case VideoGestureAction.brightness:
        brightness = VideoGesturePolicy.level(
          origin: initialBrightness,
          dy: dy,
          height: size.height,
        );
        unawaited(
          VideoDisplayService.brightness(brightness).catchError((Object _) {}),
        );
        hint = '亮度 ${(brightness * 100).round()}%';
        break;
      case VideoGestureAction.volume:
        final value = VideoGesturePolicy.level(
          origin: initialVolume,
          dy: dy,
          height: size.height,
        );
        unawaited(
          ref.read(audioPlayerControllerProvider.notifier).setVolume(value),
        );
        hint = '音量 ${(value * 100).round()}%';
        break;
    }
    setState(() {});
  }

  void finishGesture() {
    if (preview != null &&
        gestureTrack == ref.read(audioPlayerServiceProvider).currentTrack) {
      unawaited(
        ref
            .read(audioPlayerControllerProvider.notifier)
            .seekAndPersist(preview!),
      );
    }
    setState(() {
      preview = null;
      action = VideoGestureAction.none;
    });
    scheduleHide();
  }

  String time(Duration duration) {
    final s = duration.inSeconds.clamp(0, 2147483647);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(lyricAutoLoaderProvider);
    final track = ref.watch(currentTrackProvider).valueOrNull;
    if (gestureTrack != null && gestureTrack != track) {
      preview = null;
      hint = null;
      action = VideoGestureAction.none;
      gestureTrack = null;
    }
    if (widget.fullscreen && track != null && !track.isVideo && !closing) {
      closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
    final position =
        preview ?? ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final playing = ref.watch(isPlayingProvider);
    final lyrics = ref.watch(lyricControllerProvider);
    final matching = ref
        .read(lyricControllerProvider.notifier)
        .navigationStartsFor(track)
        .isNotEmpty;
    final active = matching
        ? lyrics.displayLyrics
              .where(
                (line) => line.startTime <= position && position < line.endTime,
              )
              .map((line) => line.text)
              .join('\n')
        : '';
    final subtitle = matching ? active : (status['subtitles'] as String? ?? '');
    final frame = VideoFrame(
      status: status,
      subtitle: subtitle,
      subtitleBottom: widget.fullscreen && controls ? 72 : 18,
    );
    final content = LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          if (widget.fullscreen)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggleControls,
              onDoubleTapDown: (d) => doubleForward =
                  d.localPosition.dx >= constraints.maxWidth / 2,
              onDoubleTap: navigate,
              onPanStart: startGesture,
              onPanUpdate: (d) => updateGesture(
                d,
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
              onPanEnd: (_) => finishGesture(),
              onPanCancel: () {
                setState(() {
                  preview = null;
                  action = VideoGestureAction.none;
                });
                scheduleHide();
              },
              child: frame,
            )
          else
            frame,
          if (error != null)
            Center(
              child: Text(error!, style: const TextStyle(color: Colors.white)),
            ),
          if (hint != null)
            Center(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      hint!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (!widget.fullscreen)
            Positioned(
              right: 4,
              bottom: 2,
              child: IconButton(
                tooltip: '视频全屏',
                color: Colors.white,
                icon: const Icon(Icons.fullscreen),
                onPressed: () => VideoPlayerView.openFullscreen(context),
              ),
            ),
          if (widget.fullscreen && controls) ...[
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    tooltip: '退出全屏',
                    color: Colors.white,
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      track?.title ?? '视频',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 12,
              right: 12,
              child: ColoredBox(
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: '上一首',
                          color: Colors.white,
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () => ref
                              .read(audioPlayerControllerProvider.notifier)
                              .skipToPrevious(),
                        ),
                        IconButton(
                          tooltip: playing ? '暂停' : '播放',
                          color: Colors.white,
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          onPressed: () {
                            final controller = ref.read(
                              audioPlayerControllerProvider.notifier,
                            );
                            if (playing) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            scheduleHide();
                          },
                        ),
                        IconButton(
                          tooltip: '下一首',
                          color: Colors.white,
                          icon: const Icon(Icons.skip_next),
                          onPressed: () => ref
                              .read(audioPlayerControllerProvider.notifier)
                              .skipToNext(),
                        ),
                        Expanded(
                          child: Slider(
                            value: duration.inMilliseconds > 0
                                ? (position.inMilliseconds /
                                          duration.inMilliseconds)
                                      .clamp(0, 1)
                                : 0,
                            onChangeStart: (_) {
                              gestureTrack = ref
                                  .read(audioPlayerServiceProvider)
                                  .currentTrack;
                              hideTimer?.cancel();
                            },
                            onChanged: duration > Duration.zero
                                ? (value) {
                                  if (gestureTrack !=
                                      ref
                                          .read(audioPlayerServiceProvider)
                                          .currentTrack) {
                                    return;
                                  }
                                    setState(
                                      () => preview = Duration(
                                        milliseconds:
                                            (value * duration.inMilliseconds)
                                                .round(),
                                      ),
                                    );
                                  }
                                : null,
                            onChangeEnd: (_) => finishGesture(),
                          ),
                        ),
                        Text(
                          '${time(position)} / ${time(duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return widget.fullscreen
        ? SafeArea(child: content)
        : AspectRatio(
            aspectRatio: VideoFrame(status: status).aspectRatio,
            child: content,
          );
  }
}
