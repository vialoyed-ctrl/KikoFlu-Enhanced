import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/work.dart';
import '../utils/tag_localizer.dart';
import 'metadata_search_chip.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final FontWeight? fontWeight;

  const TagChip({
    super.key,
    required this.tag,
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
    final locale = Localizations.localeOf(context);
    final localizedName = TagLocalizer.localize(tag.id, tag.name, locale);

    return MetadataSearchChip(
      label: localizedName,
      searchKeyword: localizedName,
      searchTypeLabel: S.of(context).searchTypeTag,
      searchParams: {'tagId': tag.id, 'tagName': tag.name},
      chipTone: MetadataChipTone.secondary,
      customTone: MetadataChipTone.primary,
      muted: tag.isUserAdded,
      onDeleted: onDeleted,
      onTap: onTap,
      onLongPress: onLongPress,
      compact: compact,
      fontSize: fontSize,
      padding: padding,
      borderRadius: borderRadius,
      fontWeight: fontWeight,
      logName: 'tag',
      logId: tag.id,
    );
  }
}
