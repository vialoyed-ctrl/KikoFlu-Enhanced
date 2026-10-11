import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/file_icon_utils.dart';
import 'file_tree_view.dart';

typedef FileTreeActionHandler = void Function(dynamic item, String parentPath);

class FileTreeActions extends StatelessWidget {
  const FileTreeActions({
    super.key,
    required this.entry,
    this.onPlayAudio,
    this.onPlayVideo,
    this.onLoadSubtitle,
    this.onPreviewImage,
    this.onPreviewText,
    this.onPreviewPdf,
    this.onDelete,
    this.showPlaybackActions = true,
    this.showPreviewActions = true,
    this.showDeleteAction = false,
  });

  final FileTreeEntry entry;
  final FileTreeActionHandler? onPlayAudio;
  final FileTreeActionHandler? onPlayVideo;
  final FileTreeActionHandler? onLoadSubtitle;
  final FileTreeActionHandler? onPreviewImage;
  final FileTreeActionHandler? onPreviewText;
  final FileTreeActionHandler? onPreviewPdf;
  final FileTreeActionHandler? onDelete;
  final bool showPlaybackActions;
  final bool showPreviewActions;
  final bool showDeleteAction;

  @override
  Widget build(BuildContext context) {
    if (entry.isFolder) return const SizedBox.shrink();

    final item = entry.item;

    if (showPlaybackActions) {
      final playbackAction = _buildPlaybackAction(item);
      if (playbackAction != null) return playbackAction;
    }

    final actions = <Widget>[
      if (_canLoadAsSubtitle(item))
        IconButton(
          onPressed: () => onLoadSubtitle?.call(item, entry.parentPath),
          icon: const Icon(Icons.subtitles),
          color: Colors.orange,
          tooltip: S.of(context).loadAsSubtitle,
          iconSize: 20,
        ),
      if (showPreviewActions && _isPreviewable(item))
        IconButton(
          onPressed: () => _preview(item),
          icon: const Icon(Icons.visibility),
          color: Colors.blue,
          tooltip: S.of(context).preview,
          iconSize: 20,
        ),
      if (showDeleteAction && onDelete != null)
        IconButton(
          onPressed: () => onDelete?.call(item, entry.parentPath),
          icon: const Icon(Icons.delete_outline),
          color: Colors.red.shade400,
          tooltip: S.of(context).delete,
          iconSize: 20,
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget? _buildPlaybackAction(dynamic item) {
    if (FileIconUtils.isAudioFile(item) && onPlayAudio != null) {
      return IconButton(
        onPressed: () => onPlayAudio?.call(item, entry.parentPath),
        icon: const Icon(Icons.play_arrow),
        color: Colors.green,
        iconSize: 20,
      );
    }

    if (FileIconUtils.isVideoFile(item) && onPlayVideo != null) {
      return IconButton(
        onPressed: () => onPlayVideo?.call(item, entry.parentPath),
        icon: const Icon(Icons.video_library),
        color: Colors.blue,
        iconSize: 20,
      );
    }

    return null;
  }

  bool _canLoadAsSubtitle(dynamic item) {
    return onLoadSubtitle != null &&
        FileIconUtils.isTextFile(item) &&
        FileIconUtils.isLyricFile(entry.originalTitle);
  }

  bool _isPreviewable(dynamic item) {
    return FileIconUtils.isImageFile(item) ||
        FileIconUtils.isTextFile(item) ||
        FileIconUtils.isPdfFile(item);
  }

  void _preview(dynamic item) {
    if (FileIconUtils.isImageFile(item)) {
      onPreviewImage?.call(item, entry.parentPath);
    } else if (FileIconUtils.isPdfFile(item)) {
      onPreviewPdf?.call(item, entry.parentPath);
    } else {
      onPreviewText?.call(item, entry.parentPath);
    }
  }
}
