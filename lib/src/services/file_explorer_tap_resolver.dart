import '../utils/file_icon_utils.dart';

enum FileExplorerTapAction {
  audio,
  video,
  image,
  pdf,
  text,
  unsupported,
}

class FileExplorerTapResolver {
  const FileExplorerTapResolver({
    this.videoBeforeAudio = true,
  });

  final bool videoBeforeAudio;

  FileExplorerTapAction resolve(dynamic file) {
    if (videoBeforeAudio) {
      final mediaAction = _resolveVideoOrAudio(file);
      if (mediaAction != null) return mediaAction;
    } else {
      final mediaAction = _resolveAudioOrVideo(file);
      if (mediaAction != null) return mediaAction;
    }

    if (FileIconUtils.isImageFile(file)) return FileExplorerTapAction.image;
    if (FileIconUtils.isPdfFile(file)) return FileExplorerTapAction.pdf;
    if (FileIconUtils.isTextFile(file)) return FileExplorerTapAction.text;
    return FileExplorerTapAction.unsupported;
  }

  FileExplorerTapAction? _resolveVideoOrAudio(dynamic file) {
    if (FileIconUtils.isVideoFile(file)) return FileExplorerTapAction.video;
    if (FileIconUtils.isAudioFile(file)) return FileExplorerTapAction.audio;
    return null;
  }

  FileExplorerTapAction? _resolveAudioOrVideo(dynamic file) {
    if (FileIconUtils.isAudioFile(file)) return FileExplorerTapAction.audio;
    if (FileIconUtils.isVideoFile(file)) return FileExplorerTapAction.video;
    return null;
  }
}
