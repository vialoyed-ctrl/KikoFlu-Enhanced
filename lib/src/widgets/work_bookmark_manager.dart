import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/my_reviews_provider.dart';
import '../utils/snackbar_util.dart';
import '../../l10n/app_localizations.dart';
import 'review_progress_dialog.dart';

/// 作品标记管理器 - 封装标记状态的逻辑和UI
/// 可被多个页面复用，确保状态和刷新机制一致
class WorkBookmarkManager {
  final WidgetRef ref;
  final BuildContext context;

  WorkBookmarkManager({
    required this.ref,
    required this.context,
  });

  /// 显示标记对话框并处理更新
  /// 返回包含进度和评分的Map（如果有变化）
  Future<Map<String, dynamic>?> showMarkDialog({
    required int workId,
    required String? currentProgress,
    required int? currentRating,
    required Function(String? newProgress, int? newRating) onChanged,
    String? workTitle,
  }) async {
    final s = S.of(context);
    final result = await ReviewProgressDialog.show(
      context: context,
      currentProgress: currentProgress,
      currentRating: currentRating,
      title: s.markWork,
      workId: workId,
      workTitle: workTitle,
    );

    if (result == null || !context.mounted) {
      return null;
    }

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);

      if (result['progress'] == '__REMOVE__') {
        // 删除标记
        await apiService.deleteReview(workId);
        if (!context.mounted) return null;

        SnackBarUtil.showSuccess(context, s.bookmarkRemoved);

        // 更新状态
        onChanged(null, null);

        // 刷新我的评论列表
        ref.read(myReviewsProvider.notifier).load(refresh: true);

        return {'progress': null, 'rating': null};
      } else {
        // 构建提示消息
        final newProgress = result['progress'] as String?;
        final newRating = result['rating'] as int?;
        final message = _buildUpdateMessage(
          context,
          s,
          newProgress: newProgress,
          newRating: newRating,
        );

        // 更新标记（包括进度和评分）
        await apiService.updateReviewProgress(
          workId,
          progress: newProgress,
          rating: newRating,
        );
        if (!context.mounted) return null;

        SnackBarUtil.showSuccess(context, message);

        // 更新状态
        onChanged(newProgress, newRating);

        // 刷新我的评论列表
        ref.read(myReviewsProvider.notifier).load(refresh: true);

        return result;
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtil.showError(
            context, s.operationFailedWithError(e.toString()));
      }
    }

    return null;
  }

  String _buildUpdateMessage(
    BuildContext context,
    S s, {
    required String? newProgress,
    required int? newRating,
  }) {
    if (newProgress != null && newRating != null) {
      // 同时设置了进度和评分
      final filterLabel =
          ReviewProgressDialog.getProgressLabel(newProgress, context);
      return s.setProgressAndRating(filterLabel, newRating);
    } else if (newProgress != null) {
      // 只设置了进度
      final filterLabel =
          ReviewProgressDialog.getProgressLabel(newProgress, context);
      return s.setProgressTo(filterLabel);
    } else if (newRating != null) {
      // 只设置了评分
      return s.ratingSetTo(newRating);
    } else {
      // 都没设置（理论上不应该到这里）
      return s.updated;
    }
  }
}
