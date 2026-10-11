import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/services/storage_service.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/models/playback_navigation_settings.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/providers/lyric_provider.dart';
import 'package:kikoeru_flutter/src/providers/playback_navigation_provider.dart';
import 'package:kikoeru_flutter/src/screens/audio_player_screen.dart';
import 'package:kikoeru_flutter/src/widgets/player/video_player_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();
  runApp(const ProviderScope(child:MaterialApp(
    localizationsDelegates:S.localizationsDelegates, supportedLocales:S.supportedLocales,
    locale:Locale('zh'), home:VideoSmoke())));
}
class VideoSmoke extends ConsumerStatefulWidget {
  const VideoSmoke({super.key});
  @override ConsumerState<VideoSmoke> createState()=>_VideoSmokeState();
}
class _VideoSmokeState extends ConsumerState<VideoSmoke> {
  String message='Initializing';
  bool ready=false;
  final result=<String,dynamic>{};
  File? report;
  Timer? probeTimer;
  @override void dispose(){probeTimer?.cancel();super.dispose();}
  @override void initState(){super.initState();run();}
  Future<void> save() async { if(report!=null){await report!.writeAsString(jsonEncode(result));} }
  Future<void> run() async {
    final folder=await getExternalStorageDirectory();
    report=File('${folder!.path}/video_smoke_result.json');
    try {
      final controller=ref.read(audioPlayerControllerProvider.notifier);
      final service=ref.read(audioPlayerServiceProvider);
      // This isolated harness does not require notification permission. The
      // production entry point retains its existing initialization flow.
      setState(()=>message='Initializing audio service');
      await service.initialize().timeout(const Duration(seconds:15));
      setState(()=>message='Loading video');
      await controller.setVolume(0);
      final path='${folder.path}/video-test.mp4';
      await service.updateQueue([
        AudioTrack(id:'video1',title:'video-test.mp4',url:Uri.file(path).toString(),subtitleWorkDirPath:folder.path),
        AudioTrack(id:'video2',title:'video-test-2.mp4',url:Uri.file(path).toString(),subtitleWorkDirPath:folder.path),
      ]).timeout(const Duration(seconds:15));
      setState(()=>message='Waiting for native frame');
      unawaited(service.play());
      Map<String,dynamic> status={};
      for(var i=0;i<60;i++) {
        status=await service.getVideoStatus();
        if(status['firstFrame']==true)break;
        await Future<void>.delayed(const Duration(milliseconds:250));
      }
      await service.pause();
      if(status['firstFrame']!=true || (status['width'] as num? ??0)<=0)throw StateError('No native video frame: $status');
      result['native']=status;
      await mode(MediaNavigationMode.time);
      await service.seek(const Duration(seconds:20));
      await service.handleMediaNavigation(false);
      result['backward']=service.position.inMilliseconds;
      if((service.position.inMilliseconds-13000).abs()>150)throw StateError('Back failed');
      await service.handleMediaNavigation(true);
      result['forward']=service.position.inMilliseconds;
      if((service.position.inMilliseconds-26000).abs()>150)throw StateError('Forward failed');
      final subtitle=File('${folder.path}/video-test.srt');
      await subtitle.writeAsString('1\n00:00:00,000 --> 00:00:07,000\nFirst subtitle\n\n2\n00:00:08,000 --> 00:00:14,000\nSecond subtitle\n\n3\n00:00:15,000 --> 00:00:30,000\nThird subtitle\n');
      await Future<void>.delayed(const Duration(milliseconds:500));
      await ref.read(lyricControllerProvider.notifier).loadLyricFromLocalFile(subtitle.path);
      ref.read(lyricControllerProvider.notifier).adjustTimelineOffset(const Duration(seconds:2));
      await mode(MediaNavigationMode.subtitle);
      await service.seek(const Duration(seconds:12));
      await service.handleMediaNavigation(true);
      result['subtitleNext']=service.position.inMilliseconds;
      if((service.position.inMilliseconds-17000).abs()>150)throw StateError('Subtitle next failed');
      await service.handleMediaNavigation(false);
      result['subtitlePrevious']=service.position.inMilliseconds;
      if((service.position.inMilliseconds-10000).abs()>150)throw StateError('Subtitle previous failed');
      await mode(MediaNavigationMode.time);
      await service.seek(const Duration(seconds:20));
      result['pass']=true;
      await save();
      probeTimer=Timer.periodic(const Duration(milliseconds:500), (_) async {
        final probe={'track':service.currentTrack?.id,'title':service.currentTrack?.title,
          'position':service.position.inMilliseconds,'playing':service.playing,
          'volume':ref.read(audioPlayerControllerProvider).volume,
          'video':await service.getVideoStatus()};
        await File('${folder.path}/video_probe.json').writeAsString(jsonEncode(probe));
      });
      if(mounted)setState((){message='Native frame, seek, subtitle offset: PASS';ready=true;});
    }catch(e,st){result['pass']=false;result['error']='$e';result['stack']='$st';await save();if(mounted)setState(()=>message='$e');}
  }
  Future<void> mode(MediaNavigationMode value) async {
    await ref.read(playbackNavigationProvider.notifier).update(PlaybackNavigationSettings(
      backwardSeconds:7,forwardSeconds:13,mode:value));
  }
  @override Widget build(BuildContext context){
    if (ref.watch(currentTrackProvider).valueOrNull != null) {
      ref.watch(lyricAutoLoaderProvider);
    }
    return Scaffold(appBar:AppBar(title:const Text('Video verification')),body:Column(children:[
      Text(message),
      if(ready)const Expanded(child:Center(child:VideoPlayerView())),
      if(ready)Wrap(children:[
        TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AudioPlayerScreen())),child:const Text('播放页')),
        TextButton(onPressed:()=>VideoPlayerView.openFullscreen(context),child:const Text('全屏')),
        TextButton(onPressed:()async{await mode(MediaNavigationMode.time);await ref.read(audioPlayerServiceProvider).seek(const Duration(seconds:20));},child:const Text('时间模式')),
        TextButton(onPressed:()async{await mode(MediaNavigationMode.subtitle);await ref.read(audioPlayerServiceProvider).seek(const Duration(seconds:12));},child:const Text('字幕模式')),
      ]),
    ]));
  }
}
