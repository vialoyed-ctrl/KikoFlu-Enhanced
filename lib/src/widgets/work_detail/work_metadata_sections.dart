import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/work.dart';
import '../circle_chip.dart';
import '../tag_chip.dart';
import '../va_chip.dart';
import 'work_detail_section_title.dart';

typedef MetadataCopyCallback = void Function(String text, String label);

const _chipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
const _chipBorderRadius = 6.0;
const _chipFontSize = 12.0;
const _chipFontWeight = FontWeight.w500;

class WorkCreatorChipsSection extends StatelessWidget {
  const WorkCreatorChipsSection({
    super.key,
    required this.work,
    this.onCopy,
  });

  final Work work;
  final MetadataCopyCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final hasCircle = work.name != null && work.name!.isNotEmpty;
    final hasVas = work.vas != null && work.vas!.isNotEmpty;
    if (!hasCircle && !hasVas) return const SizedBox.shrink();

    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkDetailSectionTitle(l10n.circleAndVaSection),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (hasCircle)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CircleChip(
                  circleId: work.circleId ?? 0,
                  circleName: work.name!,
                  fontSize: _chipFontSize,
                  padding: _chipPadding,
                  borderRadius: _chipBorderRadius,
                  fontWeight: _chipFontWeight,
                  onLongPress: onCopy == null
                      ? null
                      : () => onCopy!(work.name!, l10n.circleLabel),
                ),
              ),
            if (hasVas)
              ...work.vas!.map(
                (va) => MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: VaChip(
                    va: va,
                    fontSize: _chipFontSize,
                    padding: _chipPadding,
                    borderRadius: _chipBorderRadius,
                    fontWeight: _chipFontWeight,
                    onLongPress: onCopy == null
                        ? null
                        : () => onCopy!(va.name, l10n.vaLabel),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class WorkTagChipsSection extends StatelessWidget {
  const WorkTagChipsSection({
    super.key,
    required this.tags,
    this.onTagLongPress,
    this.onTagSecondaryTap,
    this.onAddTag,
  });

  final List<Tag>? tags;
  final ValueChanged<Tag>? onTagLongPress;
  final ValueChanged<Tag>? onTagSecondaryTap;
  final VoidCallback? onAddTag;

  bool get _hasTags => tags != null && tags!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasTags) {
      if (onAddTag == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AddTagChip(
            label: S.of(context).addTag,
            onTap: onAddTag!,
            showLabel: true,
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkDetailSectionTitle(l10n.tagLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...tags!.map(
              (tag) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onSecondaryTapDown: onTagSecondaryTap == null
                      ? null
                      : (_) => onTagSecondaryTap!(tag),
                  child: TagChip(
                    tag: tag,
                    fontSize: _chipFontSize,
                    padding: _chipPadding,
                    borderRadius: _chipBorderRadius,
                    fontWeight: _chipFontWeight,
                    onLongPress: onTagLongPress == null
                        ? null
                        : () => onTagLongPress!(tag),
                  ),
                ),
              ),
            ),
            if (onAddTag != null)
              _AddTagChip(
                onTap: onAddTag!,
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AddTagChip extends StatelessWidget {
  const _AddTagChip({
    required this.onTap,
    this.label,
    this.showLabel = false,
  });

  final VoidCallback onTap;
  final String? label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add,
          size: 16,
          color: colorScheme.primary,
        ),
        if (showLabel && label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: _chipFontSize,
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: _chipPadding,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(_chipBorderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}
