import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/work.dart';
import 'work_detail_section_title.dart';

class WorkReleaseDateSection extends StatelessWidget {
  const WorkReleaseDateSection({
    super.key,
    this.release,
    this.visible = true,
  });

  final String? release;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible || release == null || release!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkDetailSectionTitle(S.of(context).releaseDate),
        const SizedBox(height: 8),
        Text(
          release!.split('T').first,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class OtherLanguageEditionsSection extends StatelessWidget {
  const OtherLanguageEditionsSection({
    super.key,
    this.editions,
    this.onEditionSelected,
  });

  final List<OtherLanguageEdition>? editions;
  final ValueChanged<OtherLanguageEdition>? onEditionSelected;

  bool get _hasEditions => editions != null && editions!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasEditions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkDetailSectionTitle(S.of(context).otherEditions),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: editions!.map((edition) {
            return _OtherLanguageEditionChip(
              edition: edition,
              onTap: onEditionSelected == null
                  ? null
                  : () => onEditionSelected!(edition),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _OtherLanguageEditionChip extends StatelessWidget {
  const _OtherLanguageEditionChip({
    required this.edition,
    this.onTap,
  });

  final OtherLanguageEdition edition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate,
              size: 14,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '「${edition.lang}」',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
