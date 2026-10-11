import 'package:flutter/services.dart';

class VideoDisplayService {
  static const channel = MethodChannel(
    'com.meteor.kikoeruflutter/video_display',
  );
  static Future<double> begin() async =>
      (await channel.invokeMethod<double>('beginFullscreen') ?? 0.5).clamp(
        0,
        1,
      );
  static Future<void> brightness(double value) =>
      channel.invokeMethod<void>('setBrightness', {'value': value.clamp(0, 1)});
  static Future<void> end() => channel.invokeMethod<void>('endFullscreen');
}
