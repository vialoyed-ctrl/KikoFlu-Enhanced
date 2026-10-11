import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/src/models/audio_effect_settings.dart';
import 'package:kikoeru_flutter/src/providers/audio_effect_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('edits persist across restart including disabled state', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AudioEffectNotifier();
    await first.ready;
    final bands = first.state.bands.toList();
    bands[3] = bands[3].copyWith(type: 1, frequency: 180, gain: -3, q: .7);
    await first.update(
      first.state.copyWith(
        enabled: false,
        width: 1.23,
        preamp: -4,
        bands: bands,
      ),
    );
    first.dispose();
    final next = AudioEffectNotifier();
    await next.ready;
    expect(next.state.enabled, false);
    expect(next.state.width, 1.23);
    expect(next.state.preamp, -4);
    expect(next.state.bands[3].toJson(), bands[3].toJson());
    next.dispose();
  });
  test('user edit wins over an in-flight preference load', () async {
    SharedPreferences.setMockInitialValues({
      AudioEffectNotifier.preferenceKey: jsonEncode(
        AudioEffectSettings.original().toJson(),
      ),
    });
    final controller = AudioEffectNotifier();
    await controller.update(
      AudioEffectSettings.reference().copyWith(width: 1.75),
    );
    await controller.ready;
    expect(controller.state.width, 1.75);
    expect(controller.state.enabled, true);
    controller.dispose();
  });
  test('corrupt saved configuration restores screenshot defaults', () async {
    SharedPreferences.setMockInitialValues({
      AudioEffectNotifier.preferenceKey: 'broken json',
    });
    final controller = AudioEffectNotifier();
    await controller.ready;
    expect(controller.state.toJson(), AudioEffectSettings.reference().toJson());
    controller.dispose();
  });
}
