import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/work.dart';
import 'metadata_search_chip.dart';

class VaChip extends StatelessWidget {
  final Va va;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final FontWeight? fontWeight;

  const VaChip({
    super.key,
    required this.va,
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
      label: va.name,
      searchKeyword: va.name,
      searchTypeLabel: S.of(context).searchTypeVa,
      searchParams: {'vaId': va.id, 'vaName': va.name},
      chipTone: MetadataChipTone.tertiary,
      onDeleted: onDeleted,
      onTap: onTap,
      onLongPress: onLongPress,
      compact: compact,
      fontSize: fontSize,
      padding: padding,
      borderRadius: borderRadius,
      fontWeight: fontWeight,
      logName: 'VA',
      logId: va.id,
    );
  }
}
