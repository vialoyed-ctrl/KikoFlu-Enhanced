import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

class LoadSubtitleConfirmationDialog extends StatelessWidget {
  const LoadSubtitleConfirmationDialog({
    super.key,
    required this.subtitleTitle,
    required this.currentAudioTitle,
  });

  final String subtitleTitle;
  final String currentAudioTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveAlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.subtitles,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(l10n.loadSubtitle),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loadSubtitleConfirm,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SubtitleSelectionSummary(
              subtitleTitle: subtitleTitle,
              currentAudioTitle: currentAudioTitle,
            ),
            const SizedBox(height: 16),
            const _AutoRestoreNote(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.confirmLoad),
        ),
      ],
    );
  }
}

class _SubtitleSelectionSummary extends StatelessWidget {
  const _SubtitleSelectionSummary({
    required this.subtitleTitle,
    required this.currentAudioTitle,
  });

  final String subtitleTitle;
  final String currentAudioTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLabel(
            icon: Icons.closed_caption,
            label: l10n.subtitleFile,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            subtitleTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryLabel(
            icon: Icons.music_note,
            label: l10n.currentAudio,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            currentAudioTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AutoRestoreNote extends StatelessWidget {
  const _AutoRestoreNote();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.subtitleAutoRestoreNote,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showLoadSubtitleConfirmationDialog(
  BuildContext context, {
  required String subtitleTitle,
  required String currentAudioTitle,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => LoadSubtitleConfirmationDialog(
      subtitleTitle: subtitleTitle,
      currentAudioTitle: currentAudioTitle,
    ),
  );

  return confirmed == true;
}
