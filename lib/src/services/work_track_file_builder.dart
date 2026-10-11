import '../models/work.dart';

class WorkTrackFileBuilder {
  const WorkTrackFileBuilder({
    required this.host,
    required this.token,
  });

  final String host;
  final String token;

  Work withTracks({
    required Work work,
    required List<dynamic> files,
  }) {
    return work.copyWith(children: toAudioFiles(files));
  }

  List<AudioFile> toAudioFiles(List<dynamic> files) {
    return _toAudioFiles(files, _normalizedHost);
  }

  List<AudioFile> _toAudioFiles(List<dynamic> files, String normalizedHost) {
    return files.map((file) {
      final fileMap = Map<String, dynamic>.from(file as Map);
      final type = fileMap['type'] as String?;
      final title =
          fileMap['title'] as String? ?? fileMap['name'] as String? ?? '';
      final hash = fileMap['hash'] as String?;
      final size = fileMap['size'] as int?;

      List<AudioFile>? children;
      final rawChildren = fileMap['children'];
      if (rawChildren is List) {
        children = _toAudioFiles(rawChildren, normalizedHost);
      }

      return AudioFile(
        title: title,
        hash: hash,
        type: type == 'folder' ? 'folder' : 'file',
        children: children,
        size: size,
        mediaDownloadUrl: _downloadUrlFor(fileMap, normalizedHost, hash, type),
      );
    }).toList();
  }

  String? _downloadUrlFor(
    Map<String, dynamic> file,
    String normalizedHost,
    String? hash,
    String? type,
  ) {
    final mediaStreamUrl = file['mediaStreamUrl'];
    if (mediaStreamUrl != null && mediaStreamUrl.toString().isNotEmpty) {
      return mediaStreamUrl.toString();
    }

    if (normalizedHost.isEmpty || hash == null || type == 'folder') {
      return null;
    }

    return '$normalizedHost/api/media/stream/$hash?token=$token';
  }

  String get _normalizedHost {
    if (host.isEmpty ||
        host.startsWith('http://') ||
        host.startsWith('https://')) {
      return host;
    }

    return 'https://$host';
  }
}
