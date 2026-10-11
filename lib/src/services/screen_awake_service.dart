import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenAwakeService {
  static const MethodChannel _channel =
      MethodChannel('com.meteor.kikoeruflutter/screen_awake');

  static bool? _lastEnabled;

  static Future<void> setEnabled(bool enabled) async {
    if (_lastEnabled == enabled) return;
    _lastEnabled = enabled;

    try {
      await _channel.invokeMethod<void>(
        'setKeepScreenOn',
        {'enabled': enabled},
      );
    } on MissingPluginException {
      // Unsupported platforms do not need to fail user flows.
    } on PlatformException catch (e) {
      debugPrint('Failed to update screen-awake state: ${e.message}');
    }
  }

  @visibleForTesting
  static void debugReset() {
    _lastEnabled = null;
  }
}
