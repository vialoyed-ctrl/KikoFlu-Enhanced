import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/services/subtitle_folder_binding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'explicit file choice survives restart and clears on folder change',
    () async {
      SharedPreferences.setMockInitialValues({});
      const track = AudioTrack(
        id: '1',
        title: '02.wav',
        url: 'one',
        workId: 350815,
      );
      await SubtitleFolderBindingService.bind(
        track,
        '已解析/RJ350815',
        file: '已解析/RJ350815/02 alternate.lrc',
      );
      expect(
        await SubtitleFolderBindingService.selectedFile(track),
        '已解析/RJ350815/02 alternate.lrc',
      );
      await SubtitleFolderBindingService.bind(track, '已解析/other');
      expect(await SubtitleFolderBindingService.selectedFile(track), isNull);
    },
  );
  test(
    'work folder binding is shared by tracks and remains relative after relocation',
    () async {
      SharedPreferences.setMockInitialValues({});
      const first = AudioTrack(
        id: '1',
        title: '01.wav',
        url: 'one',
        workId: 350815,
      );
      const second = AudioTrack(
        id: '2',
        title: '02.wav',
        url: 'two',
        workId: 350815,
      );
      const other = AudioTrack(
        id: '3',
        title: '01.wav',
        url: 'three',
        workId: 5213146,
      );
      await SubtitleFolderBindingService.bind(first, '已解析/RJ350815/version');
      expect(
        await SubtitleFolderBindingService.binding(second),
        '已解析/RJ350815/version',
      );
      expect(await SubtitleFolderBindingService.binding(other), isNull);
      await SubtitleFolderBindingService.bind(second, null);
      expect(await SubtitleFolderBindingService.binding(first), isNull);
    },
  );
  test('missing work metadata can use RJ in the source path', () {
    const track = AudioTrack(
      id: '1',
      title: '01.wav',
      url: 'one',
      sourcePath: '/audio/RJ0213146/01.wav',
    );
    expect(SubtitleFolderBindingService.workId(track), 213146);
  });
}
