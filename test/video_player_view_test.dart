import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/player/video_player_view.dart';

void main() {
  test('frame aspect ratio uses dimensions and pixel ratio with safe fallback', () {
    expect(const VideoFrame(status:{}).aspectRatio, 16/9);
    expect(const VideoFrame(status:{'width':1920,'height':1080,'pixelRatio':1}).aspectRatio, 16/9);
    expect(const VideoFrame(status:{'width':720,'height':576,'pixelRatio':1.6}).aspectRatio, 2);
  });
  testWidgets('frame fits both narrow portrait and landscape without overflow', (tester) async {
    for (final size in [const Size(272,160), const Size(640,320)]) {
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:Center(child:SizedBox(
        width:size.width,height:size.height,child:const VideoFrame(
          status:{'width':1920,'height':1080,'firstFrame':true}, subtitle:'Demo subtitles'))))));
      await tester.pump();
      expect(find.text('Demo subtitles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
