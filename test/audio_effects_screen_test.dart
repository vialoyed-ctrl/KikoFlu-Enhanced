import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/src/providers/audio_effect_provider.dart';
import 'package:kikoeru_flutter/src/screens/audio_effects_screen.dart';

void main() {
  testWidgets('editing a band preserves fractional frequency and Q', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await container.read(audioEffectProvider.notifier).ready;
    final s = container.read(audioEffectProvider);
    final bands = s.bands.toList();
    bands[0] = bands[0].copyWith(frequency: 432.5, q: 3.255);
    await container
        .read(audioEffectProvider.notifier)
        .update(s.copyWith(bands: bands));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AudioEffectsScreen()),
      ),
    );
    await tester.ensureVisible(find.byIcon(Icons.tune).first);
    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(audioEffectProvider).bands[0].frequency, 432.5);
    expect(container.read(audioEffectProvider).bands[0].q, 3.255);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  testWidgets('default config can be edited, disabled and restored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await container.read(audioEffectProvider.notifier).ready;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AudioEffectsScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('7.2 dB'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(audioEffectProvider).enabled, false);
    final slider = tester.widget<Slider>(find.byType(Slider).first);
    slider.onChanged!(-3);
    await tester.pump();
    expect(container.read(audioEffectProvider).preamp, -3);
    await tester.tap(find.text('Screenshot defaults'));
    await tester.pump();
    expect(container.read(audioEffectProvider).preamp, 7.2);
    expect(container.read(audioEffectProvider).enabled, true);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
