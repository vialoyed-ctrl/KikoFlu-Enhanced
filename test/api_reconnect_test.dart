import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/kikoeru_api_service.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:kikoeru_flutter/src/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.meteor.kikoeruflutter/system_proxy');
  for (final initialMode in [ProxyMode.system, ProxyMode.manual]) {
    test(
      'a new request follows the system proxy after its port changes from ${initialMode.name}',
      () async {
        SharedPreferences.setMockInitialValues({'proxy_mode': 'system'});
        final storage = await Directory.systemTemp.createTemp(
          'kiko-reconnect-test',
        );
        Hive.init(storage.path);
        addTearDown(() async {
          await Hive.close();
          await storage.delete(recursive: true);
        });
        await StorageService.init();
        final oldOverride = HttpOverrides.current;
        HttpOverrides.global = KikoFluHttpOverrides();
        final servers = <HttpServer>[];
        Future<HttpServer> start(int id) async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          servers.add(server);
          server.listen((request) async {
            expect(
              request.headers.value('authorization'),
              'Bearer retained-token',
            );
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'works': [
                  {'id': id, 'title': 'Recovered'},
                ],
                'pagination': {'totalCount': 1, 'currentPage': 1},
              }),
            );
            await request.response.close();
          });
          return server;
        }

        var proxy = await start(1);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              channel,
              (_) async => '127.0.0.1:${proxy.port}',
            );
        addTearDown(() async {
          HttpOverrides.global = oldOverride;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
          for (final server in servers) {
            await server.close(force: true);
          }
        });
        await ProxyConfig.init();
        await ProxyConfig.saveMode(initialMode, '127.0.0.1:${proxy.port}');
        final api = KikoeruApiService()
          ..init('retained-token', 'http://example.test');
        expect((await api.getWorks(pageSize: 12))['works'][0]['id'], 1);
        await proxy.close(force: true);
        proxy = await start(2);
        await ProxyConfig.saveMode(ProxyMode.system, '');
        final result = await api.getWorks(pageSize: 12);
        expect(result['works'][0]['id'], 2);
      },
    );
  }
  test(
    'response-stage disconnect recovers GET while a healthy POST drains; failed POST is not replayed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await Directory.systemTemp.createTemp(
        'kiko-concurrent-test',
      );
      Hive.init(storage.path);
      await StorageService.init();
      final oldOverride = HttpOverrides.current;
      HttpOverrides.global = KikoFluHttpOverrides();
      await ProxyConfig.saveMode(ProxyMode.direct, '');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        HttpOverrides.global = oldOverride;
        await server.close(force: true);
        await Hive.close();
        await storage.delete(recursive: true);
      });
      var gets = 0;
      var posts = 0;
      final postStarted = Completer<void>();
      final finishPost = Completer<void>();
      server.listen((request) async {
        if (request.method == 'POST') {
          posts++;
          await request.drain<void>();
          if (posts == 1) {
            postStarted.complete();
            await finishPost.future;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'ok': true}));
            await request.response.close();
          } else {
            (await request.response.detachSocket(
              writeHeaders: false,
            )).destroy();
          }
        } else {
          gets++;
          if (gets == 1) {
            (await request.response.detachSocket(
              writeHeaders: false,
            )).destroy();
          } else {
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'works': [
                  {'id': 2, 'title': 'Recovered'},
                ],
                'pagination': {'totalCount': 1, 'currentPage': 1},
              }),
            );
            await request.response.close();
          }
        }
      });
      final host = 'http://127.0.0.1:${server.port}';
      final api = KikoeruApiService()..init('', host);
      final post = api.login('test', 'test', host);
      // Attach the failure handler immediately so an aborted POST is observable.
      Object? postError;
      final observedPost = post.catchError((Object e) {
        postError = e;
        return <String, dynamic>{};
      });
      await postStarted.future;
      final result = await api.getWorks(pageSize: 12);
      expect(result['works'][0]['id'], 2);
      finishPost.complete();
      expect((await observedPost)['ok'], true);
      expect(postError, isNull);
      expect(gets, 2);
      await expectLater(
        api.login('test', 'test', host),
        throwsA(isA<KikoeruApiException>()),
      );
      expect(posts, 2);
    },
  );
}
