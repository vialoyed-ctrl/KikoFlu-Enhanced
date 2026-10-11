import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_effect_settings.dart';
import '../providers/audio_effect_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_player_service.dart';

class AudioEffectsScreen extends ConsumerStatefulWidget {
  const AudioEffectsScreen({super.key});
  @override
  ConsumerState<AudioEffectsScreen> createState() => _AudioEffectsScreenState();
}

class _AudioEffectsScreenState extends ConsumerState<AudioEffectsScreen> {
  Timer? _timer;
  Map<String, dynamic> _status = {};
  String? _statusError;
  String t(String zh, String en) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshStatus(),
    );
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await AudioPlayerService.instance.getAudioEffectStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _statusError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _statusError = t('音效状态暂不可用', 'Audio effects status unavailable'),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void update(AudioEffectSettings s) =>
      ref.read(audioEffectProvider.notifier).update(s);
  Widget slider(
    String title,
    double value,
    double min,
    double max,
    int divisions,
    String label,
    ValueChanged<double> changed,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title)),
          Text(label),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: changed,
      ),
    ],
  );
  Future<void> editBand(int index) async {
    final band = ref.read(audioEffectProvider).bands[index];
    final f = TextEditingController(text: band.frequency.toString());
    final q = TextEditingController(text: band.q.toString());
    int type = band.type;
    String? error;
    final result = await showDialog<EqBand>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('频段 ${index + 1}', 'Band ${index + 1}')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: t('滤波器类型', 'Filter type'),
                  ),
                  items: [
                    DropdownMenuItem(value: 0, child: Text(t('峰值', 'Peak'))),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(t('低架', 'Low shelf')),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(t('高架', 'High shelf')),
                    ),
                  ],
                  onChanged: (v) => type = v ?? 0,
                ),
                TextField(
                  controller: f,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: t('频率 (20–20000 Hz)', 'Frequency (20–20000 Hz)'),
                  ),
                ),
                TextField(
                  controller: q,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Q (0.2–10)'),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final frequency = double.tryParse(f.text);
                final quality = double.tryParse(q.text);
                if (frequency == null ||
                    !frequency.isFinite ||
                    frequency < 20 ||
                    frequency > 20000 ||
                    quality == null ||
                    !quality.isFinite ||
                    quality < .2 ||
                    quality > 10) {
                  setDialogState(
                    () => error = t(
                      '请输入范围内的数值',
                      'Enter values within the ranges',
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  band.copyWith(type: type, frequency: frequency, q: quality),
                );
              },
              child: Text(t('保存', 'Save')),
            ),
          ],
        ),
      ),
    );
    // Dialog exit animations may still reference the controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    f.dispose();
    q.dispose();
    if (!mounted || result == null) return;
    final current = ref.read(audioEffectProvider);
    final bands = current.bands.toList();
    bands[index] = result;
    update(current.copyWith(bands: bands));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(audioEffectProvider);
    final passthrough = ref.watch(audioPassthroughProvider);
    final status = !s.enabled
        ? t('原始模式', 'Original mode')
        : passthrough
        ? t('音频直通已开启，音效暂停', 'Audio passthrough is on; effects paused')
        : _statusError ??
              (_status['supported'] == false &&
                      (_status['sampleRate'] as num? ?? 0) > 0
                  ? t(
                      '当前音频格式暂不支持音效',
                      'Effects unavailable for this audio format',
                    )
                  : (_status['enabled'] == true &&
                        (_status['processedFrames'] as num? ?? 0) > 0)
                  ? t('音效正在处理', 'Audio effects active')
                  : t('播放后应用音效', 'Effects apply during playback'));
    return Scaffold(
      appBar: AppBar(title: Text(t('音效', 'Audio effects'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(t('启用音效', 'Enable audio effects')),
            subtitle: Text(status),
            value: s.enabled,
            onChanged: (v) => update(s.copyWith(enabled: v)),
          ),
          const SizedBox(height: 12),
          Text(
            t('预设', 'Presets'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(t('原始模式', 'Original')),
                onPressed: () => update(AudioEffectSettings.original()),
              ),
              ActionChip(
                label: Text(t('截图默认配置', 'Screenshot defaults')),
                onPressed: () => update(AudioEffectSettings.reference()),
              ),
              ActionChip(
                label: const Text('ASMR'),
                onPressed: () => update(AudioEffectSettings.asmr()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          slider(
            t('增益', 'Preamp'),
            s.preamp,
            -12,
            12,
            240,
            '${s.preamp.toStringAsFixed(1)} dB',
            (v) => update(s.copyWith(preamp: v)),
          ),
          slider(
            t('立体声扩展', 'Stereo expansion'),
            s.width,
            1,
            2,
            100,
            '${((s.width - 1) * 100).round()}%',
            (v) => update(s.copyWith(width: v)),
          ),
          Text(
            t(
              '0% 保留原声场。双耳 ASMR 可降低扩展，保留定位。',
              '0% preserves the original stereo image. Reduce expansion for binaural ASMR.',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t('参数均衡器', 'Parametric equalizer'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            t(
              '点击频段右侧按钮可调整频率、Q 值和滤波器类型。设置自动保存。',
              'Edit each band’s frequency, Q and filter type. Changes are saved automatically.',
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < s.bands.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.bands[i].frequency.toStringAsFixed(0)} Hz · Q ${s.bands[i].q.toStringAsFixed(2)} · ${['Peak', 'Low shelf', 'High shelf'][s.bands[i].type]}',
                          ),
                        ),
                        IconButton(
                          tooltip: t('编辑频段', 'Edit band'),
                          onPressed: () => editBand(i),
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    slider(
                      t('频段 ${i + 1}', 'Band ${i + 1}'),
                      s.bands[i].gain,
                      -12,
                      12,
                      240,
                      '${s.bands[i].gain.toStringAsFixed(1)} dB',
                      (v) {
                        final bands = s.bands.toList();
                        bands[i] = bands[i].copyWith(gain: v);
                        update(s.copyWith(bands: bands));
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => update(AudioEffectSettings.reference()),
            icon: const Icon(Icons.restore),
            label: Text(t('恢复默认配置', 'Restore defaults')),
          ),
        ],
      ),
    );
  }
}
