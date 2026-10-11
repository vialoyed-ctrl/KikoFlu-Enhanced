import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/audio_track.dart';
import '../../providers/audio_provider.dart';
import '../../providers/lyric_provider.dart';
import '../../services/subtitle_folder_binding_service.dart';
import '../../services/subtitle_folder_matching.dart';
import '../../services/subtitle_library_service.dart';
import 'package:path/path.dart' as p;

class SubtitleMatchingDialog extends ConsumerStatefulWidget {
  const SubtitleMatchingDialog({super.key, required this.track});
  final AudioTrack track;
  @override
  ConsumerState<SubtitleMatchingDialog> createState() =>
      _SubtitleMatchingDialogState();
}

class _SubtitleMatchingDialogState
    extends ConsumerState<SubtitleMatchingDialog> {
  List<String>? _folders;
  List<String>? _files;
  String _query = '';
  String? _folder;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _query = '${SubtitleFolderBindingService.workId(widget.track) ?? ''}';
    _load();
  }

  Future<void> _load() async {
    try {
      final folders = await SubtitleFolderBindingService.folders();
      if (mounted) setState(() => _folders = folders);
    } catch (e) {
      if (mounted) setState(() => _error = '读取字幕库失败：$e');
    }
  }

  Future<void> _open(String folder) async {
    setState(() {
      _folder = folder;
      _files = null;
      _error = null;
    });
    try {
      final files = await SubtitleFolderBindingService.files(folder);
      files.sort(
        (a, b) => (SubtitleFolderMatcher.sequence(a) ?? 9999).compareTo(
          SubtitleFolderMatcher.sequence(b) ?? 9999,
        ),
      );
      if (mounted && _folder == folder) setState(() => _files = files);
    } catch (e) {
      if (mounted) setState(() => _error = '读取文件夹失败：$e');
    }
  }

  Future<void> _save(String? selected, {bool reset = false}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (ref.read(currentTrackProvider).value != widget.track) {
        throw StateError('当前音频已切换，请重新打开字幕匹配');
      }
      if (!reset && selected == null) {
        selected = SubtitleFolderMatcher.select(
          widget.track.title,
          _files ?? [],
        );
        if (selected == null) {
          throw StateError('没有唯一对应的序号，请在列表中选择当前音频的字幕');
        }
      }
      if (!reset) {
        final root = await SubtitleLibraryService.getSubtitleLibraryDirectory();
        if (!mounted || ref.read(currentTrackProvider).value != widget.track) {
          return;
        }
        final absolute = p.joinAll([root.path, ...selected!.split('/')]);
        await ref
            .read(lyricControllerProvider.notifier)
            .loadLyricFromLocalFile(absolute);
        if (!mounted || ref.read(currentTrackProvider).value != widget.track) {
          return;
        }
        final state = ref.read(lyricControllerProvider);
        if (state.isLoading || state.lyricUrl != 'file://$absolute') {
          throw StateError('字幕加载已被其他操作替换，请重新选择');
        }
        if (state.error != null || state.lyrics.isEmpty) {
          throw StateError(state.error ?? '该字幕没有可解析的时间轴');
        }
      }
      await SubtitleFolderBindingService.bind(
        widget.track,
        reset ? null : p.dirname(selected!),
        file: reset ? null : selected,
      );
      if (!mounted || ref.read(currentTrackProvider).value != widget.track) {
        return;
      }
      if (reset) {
        final existing = ref.read(fileListControllerProvider);
        final files = existing.matches(widget.track)
            ? existing.files
            : await ref.read(playbackLyricFileTreeLoaderProvider)(widget.track);
        if (!mounted || ref.read(currentTrackProvider).value != widget.track) {
          return;
        }
        await ref
            .read(lyricControllerProvider.notifier)
            .loadLyricForTrack(widget.track, files);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = (_folders ?? [])
        .where((f) => f.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final subfolders =
        _folder == null
              ? <String>[]
              : (_files ?? <String>[])
                    .map((f) => f.substring(_folder!.length + 1).split('/'))
                    .where((parts) => parts.length > 1)
                    .map((parts) => '${_folder!}/${parts.first}')
                    .toSet()
                    .toList()
          ..sort();
    final direct = _folder == null
        ? <String>[]
        : (_files ?? <String>[]).where((f) => p.dirname(f) == _folder).toList();
    final items = _folder == null ? visible : [...subfolders, ...direct];
    return AlertDialog(
      title: const Text('字幕匹配'),
      content: SizedBox(
        width: 440,
        height: MediaQuery.sizeOf(context).height * .5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '作品：RJ${SubtitleFolderBindingService.workId(widget.track) ?? "未知"} · 音频序号：${SubtitleFolderMatcher.sequence(widget.track.title) ?? "未识别"}',
            ),
            const SizedBox(height: 8),
            if (_folder == null)
              TextFormField(
                initialValue: _query,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: '搜索字幕文件夹 / RJ号',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            if (_folder != null)
              Row(
                children: [
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _folder = null;
                            _files = null;
                          }),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      _folder!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const Text('关联会保存。切换音频后按全角或半角序号自动选择字幕。'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Expanded(
              child: _folders == null || (_folder != null && _files == null)
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? const Center(child: Text('没有找到字幕；可更换搜索词或在字幕库重载索引'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isFolder =
                            _folder == null || subfolders.contains(item);
                        return ListTile(
                          leading: Icon(
                            isFolder
                                ? Icons.folder_outlined
                                : Icons.subtitles_outlined,
                          ),
                          title: Text(
                            _folder == null ? item : p.basename(item),
                          ),
                          onTap: _saving
                              ? null
                              : () => isFolder ? _open(item) : _save(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => _save(null, reset: true),
          child: const Text('恢复自动匹配'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (_folder != null)
          FilledButton(
            onPressed: _saving ? null : () => _save(null),
            child: const Text('使用此文件夹'),
          ),
      ],
    );
  }
}
