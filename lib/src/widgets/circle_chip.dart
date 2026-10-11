import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'metadata_search_chip.dart';

class CircleChip extends StatelessWidget {
  final int circleId;
  final String circleName;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final FontWeight? fontWeight;

  const CircleChip({
    super.key,
    required this.circleId,
    required this.circleName,
    this.onDeleted,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return MetadataSearchChip(
      label: circleName,
      searchKeyword: circleName,
      searchTypeLabel: S.of(context).searchTypeCircle,
      searchParams: {'circleId': circleId, 'circleName': circleName},
      chipTone: MetadataChipTone.secondary,
      onDeleted: onDeleted,
      onTap: onTap,
      onLongPress: onLongPress,
      compact: compact,
      compactFontSize: null,
      fontSize: fontSize,
      padding: padding,
      borderRadius: borderRadius,
      fontWeight: fontWeight,
      outlined: true,
      shrinkWrapTapTarget: true,
      deleteIconSize: 16,
      logName: 'circle',
      logId: circleId,
    );
  }
}
