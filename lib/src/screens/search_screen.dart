import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../models/search_type.dart';
import '../models/kiko_search.dart';
import '../widgets/kiko_search_field.dart';
import '../providers/auth_provider.dart';
import '../providers/search_history_provider.dart';
import '../utils/l10n_extensions.dart';
import '../utils/server_utils.dart';
import '../utils/ui_tokens.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/download_fab.dart';
import '../widgets/floating_feed_toolbar.dart';
import '../widgets/liquid_glass_dropdown.dart';
import '../widgets/global_audio_player_wrapper.dart';
import 'search_result_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  double _minRate = 0;
  AgeRating _ageRating = AgeRating.all;
  SalesRange _salesRange = SalesRange.all;
  bool _showAdvancedFilters = false;

  void _directSearch(KikoSearchQuery query) {
    final filters = SearchFilters(
      minRate: _minRate,
      ageRating: _ageRating,
      salesRange: _salesRange,
    ).buildSearchKeyword().trim();
    final params = <String, dynamic>{
      'displayKeyword': query.displayText,
      'useKeywordSearch': true,
      if (filters.isNotEmpty) 'filterKeyword': filters,
      if (_minRate > 0) 'minRate': _minRate,
      if (_ageRating != AgeRating.all)
        'ageRating': _ageRating.localizedLabel(context),
      if (_salesRange != SalesRange.all)
        'salesRange': _salesRange.localizedLabel(context),
    };
    final keyword = [query.keyword, if (filters.isNotEmpty) filters].join(' ');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchResultScreen(keyword: keyword, searchParams: params),
      ),
    );
  }

  void _searchFromHistory(SearchHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultScreen(
          keyword: item.keyword,
          searchParams: item.searchParams,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlobalAudioPlayerWrapper(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          floatingActionButton: const DownloadFab(),
          appBar: ScrollableAppBar(
            title: Text(S.of(context).search, style: UiTextStyles.pageTitle),
            actions: [
              IconButton(
                tooltip: S.of(context).filter,
                icon: Icon(
                  _showAdvancedFilters
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
                onPressed: () => setState(
                  () => _showAdvancedFilters = !_showAdvancedFilters,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KikoSearchField(
                  showSearchButton: true,
                  onSearch: _directSearch,
                ),
                const SizedBox(height: 8),
                Text(
                  Localizations.localeOf(context).languageCode == 'zh'
                      ? '用空格分隔关键词，点搜索即可查询'
                      : 'Separate keywords with spaces, then search',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_showAdvancedFilters) ...[
                  const SizedBox(height: 16),
                  ..._buildAdvancedFilterSections(),
                ],
                ..._buildSearchHistory(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearchHistory(ThemeData theme) {
    final historyState = ref.watch(searchHistoryProvider);

    if (historyState.isLoading) {
      return [];
    }

    if (historyState.items.isEmpty) {
      return [];
    }

    return [
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(S.of(context).searchHistory, style: theme.textTheme.titleSmall),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(S.of(context).clearSearchHistory),
                  content: Text(S.of(context).clearSearchHistoryConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(S.of(context).cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(searchHistoryProvider.notifier).clearHistory();
                        Navigator.pop(context);
                      },
                      child: Text(S.of(context).confirm),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(S.of(context).clear),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...historyState.items.take(10).map((item) {
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: theme.colorScheme.errorContainer,
            child: Icon(Icons.delete, color: theme.colorScheme.error),
          ),
          onDismissed: (_) {
            ref.read(searchHistoryProvider.notifier).removeHistory(item.id);
          },
          child: ListTile(
            leading: Icon(Icons.history, color: theme.colorScheme.outline),
            title: Text(
              item.displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatTimestamp(item.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                ref.read(searchHistoryProvider.notifier).removeHistory(item.id);
              },
              tooltip: S.of(context).delete,
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onTap: () => _searchFromHistory(item),
          ),
        );
      }),
    ];
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  InputDecoration _filterInputDecoration(
    ThemeData theme, {
    required String labelText,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      labelStyle: theme.textTheme.labelMedium,
    );
  }

  List<Widget> _buildAdvancedFilterSections() {
    final theme = Theme.of(context);
    final filterValueStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    final authState = ref.watch(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    return [
      if (isOfficialServer) ...[
        Row(
          children: [
            const Icon(Icons.star, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${S.of(context).minRating}: ${S.of(context).minRatingStars(_minRate.toStringAsFixed(2))}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _minRate,
                    min: 0,
                    max: 5,
                    divisions: 20,
                    label: _minRate.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _minRate = value),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Expanded(
            child: FloatingToolbarSurface(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LiquidGlassDropdownButtonFormField<AgeRating>(
                initialValue: _ageRating,
                decoration: _filterInputDecoration(
                  theme,
                  labelText: S.of(context).ageRatingLabel,
                  prefixIcon: const Icon(Icons.shield),
                ),
                items: AgeRating.values
                    .where(
                      (rating) => isOfficialServer || rating != AgeRating.r15,
                    )
                    .map((rating) {
                      return DropdownMenuItem(
                        value: rating,
                        child: Text(
                          rating.localizedLabel(context),
                          style: filterValueStyle,
                        ),
                      );
                    })
                    .toList(),
                style: filterValueStyle,
                onChanged: (value) =>
                    setState(() => _ageRating = value ?? AgeRating.all),
              ),
            ),
          ),
          if (isOfficialServer) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FloatingToolbarSurface(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LiquidGlassDropdownButtonFormField<SalesRange>(
                  initialValue: _salesRange,
                  decoration: _filterInputDecoration(
                    theme,
                    labelText: S.of(context).salesLabel,
                    prefixIcon: const Icon(Icons.trending_up),
                  ),
                  items: SalesRange.values.map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(
                        range == SalesRange.all
                            ? S.of(context).salesRangeAll
                            : range.label,
                        style: filterValueStyle,
                      ),
                    );
                  }).toList(),
                  style: filterValueStyle,
                  onChanged: (value) =>
                      setState(() => _salesRange = value ?? SalesRange.all),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
    ];
  }
}
