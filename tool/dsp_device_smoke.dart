// Standalone silent device test. Build with -Ptarget=tool/dsp_device_smoke.dart
// and a separate -PkikoApplicationId. This is not the application entry point.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../lib/src/models/audio_effect_settings.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const MaterialApp(home: SmokeScreen())); }
class SmokeScreen extends StatefulWidget {
  const SmokeScreen({super.key});
  @override State<SmokeScreen> createState() => _SmokeState();
}
class _SmokeState extends State<SmokeScreen> {
  final player = AudioPlayer(handleAudioSessionActivation: false, handleInterruptions: false);
  String result = 'Running silent DSP device checks…';
  @override void initState() {super.initState();run();}
  Future<void> run() async {
    final results = <String, dynamic>{};
    try {
      const frames = 48000 * 40;
      final bytes = ByteData(44 + frames * 4);
      void ascii(int offset, String text) {for (int i=0;i<text.length;i++) {bytes.setUint8(offset+i,text.codeUnitAt(i));}}
      ascii(0,'RIFF');bytes.setUint32(4,bytes.lengthInBytes-8,Endian.little);ascii(8,'WAVE');ascii(12,'fmt ');
      bytes.setUint32(16,16,Endian.little);bytes.setUint16(20,1,Endian.little);bytes.setUint16(22,2,Endian.little);
      bytes.setUint32(24,48000,Endian.little);bytes.setUint32(28,192000,Endian.little);bytes.setUint16(32,4,Endian.little);bytes.setUint16(34,16,Endian.little);
      ascii(36,'data');bytes.setUint32(40,frames*4,Endian.little);
      for(int i=0;i<frames;i++) {final sample=(1600*sin(2*pi*1000*i/48000)).round();bytes.setInt16(44+i*4,sample,Endian.little);bytes.setInt16(46+i*4,sample~/2,Endian.little);}
      final file = File('${(await getTemporaryDirectory()).path}/dsp-smoke.wav');await file.writeAsBytes(bytes.buffer.asUint8List());
      final config = AudioEffectSettings.reference();
      await player.setVolume(0);
      await player.setKikoDsp(config.toJson());
      await player.setFilePath(file.path).timeout(const Duration(seconds: 15));
      unawaited(player.play());await Future<void>.delayed(const Duration(seconds: 3));
      results['initial'] = await player.getKikoDspStatus();
      if(results['initial']['supported']!=true || (results['initial']['processedFrames'] as num? ?? 0)<=0) {throw StateError('No processed PCM');}
      await player.setSpeed(1.1);await player.seek(const Duration(seconds: 5));await Future<void>.delayed(const Duration(seconds: 2));
      results['speed_seek'] = await player.getKikoDspStatus();
      if((results['speed_seek']['processedFrames'] as num? ?? 0)<=0) {throw StateError('DSP lost after speed/seek');}
      await player.setKikoDsp(config.copyWith(enabled:false).toJson());await Future<void>.delayed(const Duration(seconds: 1));
      results['disabled'] = await player.getKikoDspStatus();
      if(results['disabled']['enabled']!=false) {throw StateError('Disable failed');}
      await player.setKikoDsp(config.copyWith(width:1.2,preamp:-3).toJson());await Future<void>.delayed(const Duration(seconds: 2));
      results['reenabled'] = await player.getKikoDspStatus();
      if(results['reenabled']['enabled']!=true || (results['reenabled']['processedFrames'] as num? ?? 0)<=0) {throw StateError('Reenable failed');}
      await player.pause(); await player.stop();
      // Recreate native player and verify cached configuration is replayed.
      await player.setFilePath(file.path);unawaited(player.play());await Future<void>.delayed(const Duration(seconds: 2));
      results['reload'] = await player.getKikoDspStatus();
      if(results['reload']['enabled']!=true || (results['reload']['processedFrames'] as num? ?? 0)<=0) {throw StateError('Configuration lost on reload');}
      results['pass'] = true;
      await player.pause(); await player.dispose(); await file.delete();
    } catch (e, st) {results['pass']=false;results['error']=e.toString();results['stack']=st.toString();await player.dispose();}
    final folder = await getExternalStorageDirectory();
    if(folder!=null) {await File('${folder.path}/dsp_smoke_result.json').writeAsString(const JsonEncoder.withIndent('  ').convert(results));}
    if(mounted) {setState(() => result = const JsonEncoder.withIndent('  ').convert(results));}
  }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('DSP device smoke test')),body:SingleChildScrollView(padding:const EdgeInsets.all(16),child:SelectableText(result)));
}
