import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

class VideoOpenFailureDialog extends StatelessWidget {
  const VideoOpenFailureDialog.local({
    super.key,
    required this.errorMessage,
    required this.filePath,
  })  : videoUrl = null,
        onOpenInBrowser = null;

  const VideoOpenFailureDialog.remote({
    super.key,
    required this.videoUrl,
    required this.onOpenInBrowser,
  })  : errorMessage = null,
        filePath = null;

  final String? errorMessage;
  final String? filePath;
  final String? videoUrl;
  final Future<void> Function()? onOpenInBrowser;

  bool get _isRemote => videoUrl != null;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ResponsiveAlertDialog(
      title: Text(_isRemote ? l10n.cannotPlayDirectly : l10n.cannotOpenVideo),
      content: SingleChildScrollView(
        child: _isRemote ? _buildRemoteContent(l10n) : _buildLocalContent(l10n),
      ),
      actions: _isRemote
          ? _buildRemoteActions(context, l10n)
          : _buildActions(context, l10n),
    );
  }

  Widget _buildLocalContent(S l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.errorInfo(errorMessage ?? '')),
        const SizedBox(height: 12),
        Text(l10n.noVideoPlayerFound),
        const SizedBox(height: 8),
        Text(l10n.installVideoPlayerApp),
        const SizedBox(height: 12),
        Text(l10n.filePathLabel),
        SelectableText(
          filePath ?? '',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRemoteContent(S l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.noVideoPlayerFound),
        const SizedBox(height: 12),
        Text(l10n.youCan),
        Text(l10n.copyLinkToExternalPlayer),
        Text(l10n.openInBrowserOption),
        const SizedBox(height: 12),
        SelectableText(
          videoUrl ?? '',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, S l10n) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.close),
      ),
    ];
  }

  List<Widget> _buildRemoteActions(BuildContext context, S l10n) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.close),
      ),
      TextButton(
        onPressed: () async {
          Navigator.pop(context);
          await onOpenInBrowser?.call();
        },
        child: Text(l10n.openInBrowserOption),
      ),
    ];
  }
}
