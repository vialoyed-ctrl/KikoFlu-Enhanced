import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/work_id_parser.dart';

class PlaylistAddWorksDialog extends StatefulWidget {
  const PlaylistAddWorksDialog({
    super.key,
    required this.onAddWorks,
  });

  final ValueChanged<List<String>> onAddWorks;

  @override
  State<PlaylistAddWorksDialog> createState() => _PlaylistAddWorksDialogState();
}

class _PlaylistAddWorksDialogState extends State<PlaylistAddWorksDialog> {
  final TextEditingController _textController = TextEditingController();
  List<String> _parsedWorkIds = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = isLandscape ? screenWidth * 0.6 : screenWidth * 0.9;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth.clamp(300.0, 600.0),
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Text(
                      S.of(context).addWorks,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).addWorksInputHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: S.of(context).workId,
                        hintText: S.of(context).workIdHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.music_note),
                      ),
                      maxLines: 5,
                      autofocus: true,
                      onChanged: _handleInputChanged,
                    ),
                    if (_parsedWorkIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ParsedWorkIdsPreview(ids: _parsedWorkIds),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(S.of(context).cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed:
                          _parsedWorkIds.isEmpty ? null : _submitParsedIds,
                      child: Text(
                        _parsedWorkIds.isEmpty
                            ? S.of(context).add
                            : S.of(context).addNWorks(_parsedWorkIds.length),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleInputChanged(String text) {
    setState(() {
      _parsedWorkIds = WorkIdParser.extractRJIds(text);
    });
  }

  void _submitParsedIds() {
    final ids = List<String>.unmodifiable(_parsedWorkIds);
    Navigator.of(context).pop();
    widget.onAddWorks(ids);
  }
}

class _ParsedWorkIdsPreview extends StatelessWidget {
  const _ParsedWorkIdsPreview({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                S.of(context).detectedNWorkIds(ids.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ids.map((id) {
              return Chip(
                label: Text(
                  id,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
