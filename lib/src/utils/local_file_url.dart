import 'dart:io' show Platform;

class LocalFileUrl {
  LocalFileUrl._();

  static const String schemePrefix = 'file://';

  static bool isLocalFileUrl(String? value) {
    return value != null && value.startsWith(schemePrefix);
  }

  static String fromPath(String path) {
    return '$schemePrefix$path';
  }

  static String? pathFromUrl(String? url, {bool? isWindows}) {
    if (!isLocalFileUrl(url)) return null;

    final rawPath = url!.substring(schemePrefix.length);
    final decodedPath = _tryDecode(rawPath);

    if ((isWindows ?? Platform.isWindows) &&
        _looksLikeWindowsPathWithLeadingSlash(decodedPath)) {
      return decodedPath.substring(1);
    }

    return decodedPath;
  }

  static String? pathFromUrlOrPath(String? value) {
    if (value == null || value.isEmpty) return null;
    return pathFromUrl(value) ?? value;
  }

  static String _tryDecode(String path) {
    try {
      return Uri.decodeFull(path);
    } catch (_) {
      return path;
    }
  }

  static bool _looksLikeWindowsPathWithLeadingSlash(String path) {
    return path.length >= 4 &&
        path[0] == '/' &&
        _isAsciiLetter(path.codeUnitAt(1)) &&
        path[2] == ':';
  }

  static bool _isAsciiLetter(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }
}
