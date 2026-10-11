import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/screen_awake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.meteor.kikoeruflutter/screen_awake');
  final binding = TestDefaultBinaryMessengerBinding.instance;

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    ScreenAwakeService.debugReset();
  });

  test('sends screen awake updates to platform channel once per state',
      () async {
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return true;
    });

    await ScreenAwakeService.setEnabled(true);
    await ScreenAwakeService.setEnabled(true);
    await ScreenAwakeService.setEnabled(false);

    expect(calls, hasLength(2));
    expect(calls[0].method, 'setKeepScreenOn');
    expect(calls[0].arguments, {'enabled': true});
    expect(calls[1].arguments, {'enabled': false});
  });
}
