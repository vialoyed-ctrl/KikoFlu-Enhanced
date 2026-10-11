import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playback_navigation_settings.dart';
import '../../providers/playback_navigation_provider.dart';

class PlaybackNavigationDialog extends ConsumerStatefulWidget {
  const PlaybackNavigationDialog({super.key});
  @override
  ConsumerState<PlaybackNavigationDialog> createState() =>
      _PlaybackNavigationDialogState();
}

class _PlaybackNavigationDialogState
    extends ConsumerState<PlaybackNavigationDialog> {
  late final TextEditingController backward;
  late final TextEditingController forward;
  late MediaNavigationMode mode;
  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final settings = ref.read(playbackNavigationProvider);
    backward = TextEditingController(text: '${settings.backwardSeconds}');
    forward = TextEditingController(text: '${settings.forwardSeconds}');
    mode = settings.mode;
  }

  @override
  void dispose() {
    backward.dispose();
    forward.dispose();
    super.dispose();
  }

  Widget seconds(String label, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        children: [
          for (final n in [5, 10, 15, 30])
            ChoiceChip(
              label: Text('$n 秒'),
              selected: controller.text == '$n',
              onSelected: saving
                  ? null
                  : (_) => setState(() => controller.text = '$n'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        enabled: !saving,
        decoration: const InputDecoration(
          labelText: '自定义时间',
          suffixText: '秒',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        validator: (v) {
          final n = int.tryParse(v ?? '');
          return n == null || n < 1 || n > 600 ? '请输入 1–600 秒' : null;
        },
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('媒体按键与跳转设置'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('手机系统 / 耳机的上一首、下一首键'),
              const SizedBox(height: 10),
              DropdownButtonFormField<MediaNavigationMode>(
                initialValue: mode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: MediaNavigationMode.time,
                    child: Text('快进 / 快退'),
                  ),
                  DropdownMenuItem(
                    value: MediaNavigationMode.subtitle,
                    child: Text('上一段 / 下一段字幕'),
                  ),
                ],
                onChanged: saving ? null : (v) => setState(() => mode = v!),
              ),
              const SizedBox(height: 14),
              if (mode == MediaNavigationMode.subtitle)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('根据当前字幕及时间轴偏移跳转。没有可用字幕时，使用下面的快进 / 快退时间。'),
                ),
              seconds('快退时间', backward),
              const SizedBox(height: 20),
              seconds('快进时间', forward),
              const SizedBox(height: 14),
              const Text('App 内的上一首 / 下一首按钮仍然切歌。'),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  await ref
                      .read(playbackNavigationProvider.notifier)
                      .update(
                        PlaybackNavigationSettings(
                          backwardSeconds: int.parse(backward.text),
                          forwardSeconds: int.parse(forward.text),
                          mode: mode,
                        ),
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (_) {
                  if (mounted) {
                    setState(() {
                      saving = false;
                      error = '设置保存失败，请重试';
                    });
                  }
                }
              },
        child: const Text('保存'),
      ),
    ],
  );
}
