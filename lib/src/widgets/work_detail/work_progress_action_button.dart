import 'package:flutter/material.dart';

import '../review_progress_dialog.dart';

class WorkProgressActionButton extends StatelessWidget {
  const WorkProgressActionButton({
    super.key,
    this.progress,
    this.isLoading = false,
    this.onPressed,
  });

  final String? progress;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: isLoading ? _buildLoading(context) : _buildButton(context),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor =
        progress != null ? colorScheme.primary : colorScheme.onSurface;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ReviewProgressDialog.getProgressLabel(progress, context),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: activeColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            ReviewProgressDialog.getProgressIcon(progress),
            size: 22,
            color: activeColor,
          ),
        ],
      ),
    );
  }
}
