import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';

Future<void> showMetadataActions(
  BuildContext context, {
  required String label,
  required Map<String, dynamic> searchParams,
  Object? id,
  VoidCallback? onInfo,
}) async {
  final kind = searchParams.containsKey('tagName')
      ? 'tag'
      : searchParams.containsKey('vaName')
      ? 'va'
      : 'circle';
  final raw = (searchParams['${kind}Name'] ?? label) as String;
  final chinese = Localizations.localeOf(context).languageCode == 'zh';
  final messenger = ScaffoldMessenger.of(context);
  final l10n = S.of(context);
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(id == null ? label : '$label (id: $id)'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, 'copy'),
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: Text('${chinese ? '复制标签' : 'Copy label'}: $label'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, 'block'),
          child: ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text(chinese ? '添加到黑名单' : 'Add to blacklist'),
          ),
        ),
        if (onInfo != null)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'info'),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(chinese ? '标签详情与投票' : 'Tag details and votes'),
            ),
          ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (action == 'copy') {
    await Clipboard.setData(ClipboardData(text: label));
    if (context.mounted) {
      SnackBarUtil.showSuccess(
        context,
        l10n.copiedToClipboard(l10n.tagLabel, label),
      );
    }
  } else if (action == 'block') {
    final notifier = ProviderScope.containerOf(
      context,
    ).read(blockedItemsProvider.notifier);
    switch (kind) {
      case 'tag':
        await notifier.addTag(raw);
      case 'va':
        await notifier.addCv(raw);
      default:
        await notifier.addCircle(raw);
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.tagBlockedWithName(label)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            switch (kind) {
              case 'tag':
                notifier.removeTag(raw);
              case 'va':
                notifier.removeCv(raw);
              default:
                notifier.removeCircle(raw);
            }
          },
        ),
      ),
    );
  } else if (action == 'info') {
    onInfo?.call();
  }
}
