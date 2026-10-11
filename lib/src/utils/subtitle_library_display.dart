import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../services/subtitle_library_service.dart';

String localizedSubtitleFolderTitle(BuildContext context, String diskName) {
  final s = S.of(context);
  switch (diskName) {
    case SubtitleLibraryService.parsedFolderName:
      return s.subtitleFolderParsed;
    case SubtitleLibraryService.savedFolderName:
      return s.subtitleFolderSaved;
    case SubtitleLibraryService.unknownFolderName:
      return s.subtitleFolderUnknown;
    default:
      return diskName;
  }
}
