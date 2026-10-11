import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

Future<bool> showFileDeleteConfirmationDialog(
  BuildContext context, {
  required String relativePath,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => FileDeleteConfirmationDialog(
      relativePath: relativePath,
    ),
  );

  return confirmed == true;
}

class FileDeleteConfirmationDialog extends StatelessWidget {
  const FileDeleteConfirmationDialog({
    super.key,
    required this.relativePath,
  });

  final String relativePath;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return ResponsiveAlertDialog(
      title: Text(l10n.deletionConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteFilePrompt),
          const SizedBox(height: 12),
          Text(
            relativePath,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
