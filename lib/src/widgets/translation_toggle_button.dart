import 'package:flutter/material.dart';

class TranslationToggleButton extends StatelessWidget {
  const TranslationToggleButton({
    super.key,
    required this.isTranslated,
    required this.originalLabel,
    required this.translatedLabel,
    required this.onPressed,
    this.isLoading = false,
  });

  final bool isTranslated;
  final bool isLoading;
  final String originalLabel;
  final String translatedLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isTranslated
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.7);
    final borderColor = isTranslated
        ? colorScheme.primary.withValues(alpha: 0.3)
        : colorScheme.onSurface.withValues(alpha: 0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else ...[
                Icon(
                  Icons.g_translate,
                  size: 16,
                  color: foregroundColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isTranslated ? originalLabel : translatedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineTranslationButton extends StatelessWidget {
  const InlineTranslationButton({
    super.key,
    required this.isTranslated,
    required this.isLoading,
    required this.onPressed,
    this.iconSize = 18,
    this.progressSize = 16,
    this.inactiveOpacity = 0.6,
    this.padding = const EdgeInsets.only(left: 6),
    this.tooltip,
  });

  final bool isTranslated;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double iconSize;
  final double progressSize;
  final double inactiveOpacity;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = !isLoading && onPressed != null;
    final foregroundColor = isTranslated
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: inactiveOpacity);

    Widget child = Padding(
      padding: padding,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onPressed : null,
          child: isLoading
              ? SizedBox(
                  width: progressSize,
                  height: progressSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.g_translate,
                  size: iconSize,
                  color: foregroundColor,
                ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      child = Tooltip(
        message: tooltip!,
        child: child,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: child,
    );
  }
}

class TranslationToolbarButton extends StatelessWidget {
  const TranslationToolbarButton({
    super.key,
    required this.isTranslated,
    required this.isLoading,
    required this.onPressed,
    required this.tooltip,
    this.iconSize = 24,
    this.progressSize = 20,
  });

  final bool isTranslated;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String tooltip;
  final double iconSize;
  final double progressSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: progressSize,
              height: progressSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Icon(
              Icons.g_translate,
              size: iconSize,
              color: isTranslated ? colorScheme.primary : null,
            ),
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
    );
  }
}
