import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/src/models/playback_navigation_settings.dart';
import 'package:kikoeru_flutter/src/providers/playback_navigation_provider.dart';
import 'package:kikoeru_flutter/src/widgets/player/playback_navigation_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'independent times and subtitle mode survive notifier restart',
    () async {
      final first = PlaybackNavigationNotifier();
      await first.ready;
      await first.update(
        const PlaybackNavigationSettings(
          backwardSeconds: 7,
          forwardSeconds: 23,
          mode: MediaNavigationMode.subtitle,
        ),
      );
      first.dispose();
      final restored = PlaybackNavigationNotifier();
      await restored.ready;
      expect(restored.state.backwardSeconds, 7);
      expect(restored.state.forwardSeconds, 23);
      expect(restored.state.mode, MediaNavigationMode.subtitle);
      restored.dispose();
    },
  );
  testWidgets(
    'narrow settings dialog supports independent custom times and mode',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(playbackNavigationProvider.notifier).ready;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: PlaybackNavigationDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byType(DropdownButtonFormField<MediaNavigationMode>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('上一段 / 下一段字幕').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '7');
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(find.byType(TextFormField).last, '23');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final settings = container.read(playbackNavigationProvider);
      expect(settings.backwardSeconds, 7);
      expect(settings.forwardSeconds, 23);
      expect(settings.mode, MediaNavigationMode.subtitle);
      expect(tester.takeException(), isNull);
    },
  );
}
