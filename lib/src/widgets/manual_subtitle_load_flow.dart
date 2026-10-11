import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/snackbar_util.dart';
import 'load_subtitle_confirmation_dialog.dart';

typedef ManualSubtitleLoadAction = Future<void> Function(
  dynamic file, {
  required int workId,
});

typedef ManualSubtitleMountedCheck = bool Function();

Future<void> runManualSubtitleLoadFlow(
  BuildContext context, {
  required dynamic file,
  required int workId,
  required String subtitleTitle,
  required String? currentAudioTitle,
  required ManualSubtitleLoadAction loadSubtitle,
  required ManualSubtitleMountedCheck isMounted,
  Duration warningDuration = const Duration(seconds: 2),
  Duration loadingDuration = const Duration(seconds: 2),
  Duration successDuration = const Duration(seconds: 2),
  Duration errorDuration = const Duration(seconds: 4),
}) async {
  final l10n = S.of(context);

  if (currentAudioTitle == null) {
    SnackBarUtil.showWarning(
      context,
      l10n.noAudioCannotLoadSubtitle,
      duration: warningDuration,
    );
    return;
  }

  final confirmed = await showLoadSubtitleConfirmationDialog(
    context,
    subtitleTitle: subtitleTitle,
    currentAudioTitle: currentAudioTitle,
  );

  if (!confirmed || !context.mounted || !isMounted()) return;

  SnackBarUtil.showLoading(
    context,
    l10n.loadingSubtitle,
    duration: loadingDuration,
  );

  try {
    await loadSubtitle(file, workId: workId);

    if (!context.mounted || !isMounted()) return;
    SnackBarUtil.hide(context);
    SnackBarUtil.showSuccess(
      context,
      l10n.subtitleLoadSuccess(subtitleTitle),
      duration: successDuration,
    );
  } catch (e) {
    if (!context.mounted || !isMounted()) return;
    SnackBarUtil.hide(context);
    SnackBarUtil.showError(
      context,
      l10n.subtitleLoadFailed(e.toString()),
      duration: errorDuration,
    );
  }
}
