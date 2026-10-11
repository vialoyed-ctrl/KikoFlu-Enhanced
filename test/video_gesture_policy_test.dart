import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/video_gesture_policy.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';

void main() {
  test('video resources are detected by title, source path and URL path', () {
    expect(const AudioTrack(id:'1', title:'Movie.MP4', url:'https://host/stream/1').isVideo, isTrue);
    expect(const AudioTrack(id:'2', title:'clip', url:'https://host/clip.webm?token=abc').isVideo, isTrue);
    expect(const AudioTrack(id:'3', title:'clip', url:'file:///cache.audio', sourcePath:'clip.mkv').isVideo, isTrue);
    expect(const AudioTrack(id:'4', title:'song.wav', url:'https://host/audio?name=movie.mp4').isVideo, isFalse);
  });
  test('small movements remain unclassified and dominant direction selects action', () {
    expect(VideoGesturePolicy.action(dx:3,dy:2,left:true), VideoGestureAction.none);
    expect(VideoGesturePolicy.action(dx:30,dy:8,left:true), VideoGestureAction.seek);
    expect(VideoGesturePolicy.action(dx:2,dy:-25,left:true), VideoGestureAction.brightness);
    expect(VideoGesturePolicy.action(dx:2,dy:25,left:false), VideoGestureAction.volume);
  });
  test('horizontal gesture previews a bounded position without committing', () {
    expect(VideoGesturePolicy.seek(origin:const Duration(seconds:30),dx:100,width:400,duration:const Duration(seconds:120)), const Duration(seconds:60));
    expect(VideoGesturePolicy.seek(origin:const Duration(seconds:5),dx:-400,width:400,duration:const Duration(seconds:120)), Duration.zero);
    expect(VideoGesturePolicy.seek(origin:const Duration(seconds:110),dx:400,width:400,duration:const Duration(seconds:120)), const Duration(seconds:120));
  });
  test('vertical gesture upward increases level and clamps limits', () {
    expect(VideoGesturePolicy.level(origin:0.5,dy:-100,height:400), 0.75);
    expect(VideoGesturePolicy.level(origin:0.9,dy:-300,height:400), 1);
    expect(VideoGesturePolicy.level(origin:0.1,dy:300,height:400), 0);
  });
}
