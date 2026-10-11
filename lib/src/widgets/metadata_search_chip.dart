import 'package:flutter/material.dart';

import '../screens/search_result_screen.dart';
import 'metadata_action_dialog.dart';

enum MetadataChipTone { primary, secondary, tertiary }

class MetadataSearchChip extends StatelessWidget {
  final String label;
  final String searchKeyword;
  final String searchTypeLabel;
  final Map<String, dynamic> searchParams;
  final MetadataChipTone chipTone;
  final MetadataChipTone? customTone;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final FontWeight? fontWeight;
  final bool muted;
  final bool outlined;
  final bool shrinkWrapTapTarget;
  final double deleteIconSize;
  final double? compactFontSize;
  final String? logName;
  final Object? logId;

  const MetadataSearchChip({
    super.key,
    required this.label,
    required this.searchKeyword,
    required this.searchTypeLabel,
    required this.searchParams,
    required this.chipTone,
    this.customTone,
    this.onDeleted,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.fontWeight,
    this.muted = false,
    this.outlined = false,
    this.shrinkWrapTapTarget = false,
    this.deleteIconSize = 18,
    this.compactFontSize = 10,
    this.logName,
    this.logId,
  });

  bool get _usesCustomStyle =>
      fontSize != null || padding != null || borderRadius != null;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onTap ?? () => _openSearchResult(context);
    final effectiveLongPress =
        onLongPress ??
        () => showMetadataActions(
          context,
          label: label,
          searchParams: searchParams,
          id: logId,
        );

    if (_usesCustomStyle) {
      final colors = _colorsFor(context, customTone ?? chipTone);

      return GestureDetector(
        onTap: effectiveOnTap,
        onLongPress: effectiveLongPress,
        child: Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _containerColor(colors.container),
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? 11,
              color: _labelColor(colors.onContainer),
              fontWeight: fontWeight ?? FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final colors = _colorsFor(context, chipTone);
    final side = outlined
        ? BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          )
        : null;
    final labelStyle = TextStyle(
      fontSize: compact ? compactFontSize : null,
      color: _labelColor(colors.onContainer),
    );
    final effectivePadding = compact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
        : null;
    final tapTargetSize = shrinkWrapTapTarget
        ? MaterialTapTargetSize.shrinkWrap
        : null;

    if (onDeleted != null) {
      return InputChip(
        label: Text(label),
        onPressed: effectiveOnTap,
        onDeleted: onDeleted,
        deleteIcon: Icon(Icons.close, size: deleteIconSize),
        deleteIconColor: colors.onContainer,
        backgroundColor: _containerColor(colors.container),
        labelStyle: labelStyle,
        padding: effectivePadding,
        visualDensity: compact ? VisualDensity.compact : null,
        materialTapTargetSize: tapTargetSize,
        side: side,
      );
    }

    return GestureDetector(
      onLongPress: effectiveLongPress,
      child: ActionChip(
        label: Text(label),
        onPressed: effectiveOnTap,
        backgroundColor: _containerColor(colors.container),
        labelStyle: labelStyle,
        padding: effectivePadding,
        visualDensity: compact ? VisualDensity.compact : null,
        materialTapTargetSize: tapTargetSize,
        side: side,
      ),
    );
  }

  _MetadataChipColors _colorsFor(BuildContext context, MetadataChipTone tone) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (tone) {
      MetadataChipTone.primary => _MetadataChipColors(
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      MetadataChipTone.secondary => _MetadataChipColors(
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      MetadataChipTone.tertiary => _MetadataChipColors(
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
    };
  }

  Color _containerColor(Color color) =>
      muted ? color.withValues(alpha: 0.5) : color;

  Color _labelColor(Color color) =>
      muted ? color.withValues(alpha: 0.55) : color;

  void _openSearchResult(BuildContext context) {
    if (logName != null) {
      debugPrint('[MetadataSearchChip] Clicked $logName: $label, id: $logId');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          keyword: searchParams.containsKey('tagName')
              ? '\$tag:${searchParams['tagName']}\$'
              : searchParams.containsKey('vaName')
              ? '\$va:${searchParams['vaName']}\$'
              : searchParams.containsKey('circleName')
              ? '\$circle:${searchParams['circleName']}\$'
              : searchKeyword,
          searchTypeLabel: searchTypeLabel,
          searchParams: {
            ...searchParams,
            'displayKeyword': label,
            if (searchParams.containsKey('tagName') ||
                searchParams.containsKey('vaName') ||
                searchParams.containsKey('circleName'))
              'useKeywordSearch': true,
          },
        ),
      ),
    );
  }
}

class _MetadataChipColors {
  final Color container;
  final Color onContainer;

  const _MetadataChipColors(this.container, this.onContainer);
}
