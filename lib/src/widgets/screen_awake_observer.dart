import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';
import '../providers/settings_provider.dart';
import '../services/screen_awake_service.dart';

class ScreenAwakeObserver extends ConsumerStatefulWidget {
  const ScreenAwakeObserver({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ScreenAwakeObserver> createState() =>
      _ScreenAwakeObserverState();
}

class _ScreenAwakeObserverState extends ConsumerState<ScreenAwakeObserver> {
  bool? _lastRequestedEnabled;

  @override
  void dispose() {
    ScreenAwakeService.setEnabled(false);
    super.dispose();
  }

  void _apply(bool enabled) {
    if (_lastRequestedEnabled == enabled) return;
    _lastRequestedEnabled = enabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScreenAwakeService.setEnabled(enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keepAwake = ref.watch(keepScreenAwakeProvider);
    final hasTrack = ref.watch(currentTrackProvider).maybeWhen(
          data: (track) => track != null,
          orElse: () => false,
        );

    _apply(keepAwake && hasTrack);
    return widget.child;
  }
}
