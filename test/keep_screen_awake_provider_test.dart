import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncPreferenceLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keep screen awake defaults to disabled', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(keepScreenAwakeProvider), false);
    await _pumpAsyncPreferenceLoad();

    expect(container.read(keepScreenAwakeProvider), false);
  });

  test('keep screen awake loads saved preference', () async {
    SharedPreferences.setMockInitialValues({
      KeepScreenAwakeNotifier.preferenceKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(keepScreenAwakeProvider), false);
    await _pumpAsyncPreferenceLoad();

    expect(container.read(keepScreenAwakeProvider), true);
  });

  test('keep screen awake persists updates', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(keepScreenAwakeProvider.notifier).setEnabled(true);
    final prefs = await SharedPreferences.getInstance();

    expect(container.read(keepScreenAwakeProvider), true);
    expect(prefs.getBool(KeepScreenAwakeNotifier.preferenceKey), true);
  });
}
