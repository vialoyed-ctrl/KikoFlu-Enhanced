import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/local_file_url.dart';

typedef OpenLocalVideoFile = Future<OpenResult> Function(String path);
typedef CanLaunchVideoUri = Future<bool> Function(Uri uri);
typedef LaunchVideoUri = Future<bool> Function(
  Uri uri, {
  required LaunchMode mode,
});

enum VideoOpenResultType {
  success,
  localOpenFailed,
  localOpenError,
  remoteCannotLaunch,
  remoteOpenError,
}

class VideoOpenResult {
  const VideoOpenResult._({
    required this.type,
    this.message,
    this.path,
    this.uri,
  });

  const VideoOpenResult.success() : this._(type: VideoOpenResultType.success);

  const VideoOpenResult.localOpenFailed({
    required String message,
    required String path,
  }) : this._(
          type: VideoOpenResultType.localOpenFailed,
          message: message,
          path: path,
        );

  const VideoOpenResult.localOpenError({
    required String message,
    required String path,
  }) : this._(
          type: VideoOpenResultType.localOpenError,
          message: message,
          path: path,
        );

  const VideoOpenResult.remoteCannotLaunch(Uri uri)
      : this._(
          type: VideoOpenResultType.remoteCannotLaunch,
          uri: uri,
        );

  const VideoOpenResult.remoteOpenError({
    required String message,
    required Uri uri,
  }) : this._(
          type: VideoOpenResultType.remoteOpenError,
          message: message,
          uri: uri,
        );

  final VideoOpenResultType type;
  final String? message;
  final String? path;
  final Uri? uri;

  bool get isSuccess => type == VideoOpenResultType.success;
}

class VideoFileOpener {
  VideoFileOpener({
    OpenLocalVideoFile? openLocalFile,
    CanLaunchVideoUri? canLaunch,
    LaunchVideoUri? launch,
  })  : _openLocalFile = openLocalFile ?? OpenFilex.open,
        _canLaunch = canLaunch ?? canLaunchUrl,
        _launch = launch ??
            ((uri, {required mode}) {
              return launchUrl(uri, mode: mode);
            });

  final OpenLocalVideoFile _openLocalFile;
  final CanLaunchVideoUri _canLaunch;
  final LaunchVideoUri _launch;

  Future<VideoOpenResult> open(String source) {
    final localPath = LocalFileUrl.pathFromUrl(source);
    if (localPath != null) {
      return openLocalPath(localPath);
    }

    return openRemoteUri(Uri.parse(source));
  }

  Future<VideoOpenResult> openLocalPath(String path) async {
    try {
      final result = await _openLocalFile(path);
      if (result.type == ResultType.done) {
        return const VideoOpenResult.success();
      }

      return VideoOpenResult.localOpenFailed(
        message: result.message,
        path: path,
      );
    } catch (e) {
      return VideoOpenResult.localOpenError(
        message: e.toString(),
        path: path,
      );
    }
  }

  Future<VideoOpenResult> openRemoteUri(Uri uri) async {
    try {
      final canLaunch = await _canLaunch(uri);
      if (!canLaunch) {
        return VideoOpenResult.remoteCannotLaunch(uri);
      }

      final launched = await _launch(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return const VideoOpenResult.success();
      }

      final fallbackLaunched = await _launch(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (fallbackLaunched) {
        return const VideoOpenResult.success();
      }

      return VideoOpenResult.remoteCannotLaunch(uri);
    } catch (e) {
      return VideoOpenResult.remoteOpenError(
        message: e.toString(),
        uri: uri,
      );
    }
  }

  Future<bool> openInBrowser(Uri uri) {
    return _launch(uri, mode: LaunchMode.platformDefault);
  }
}
