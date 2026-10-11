import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../models/kiko_search.dart';
import '../models/search_type.dart';
import '../providers/auth_provider.dart';
import '../utils/l10n_extensions.dart';

final kikoSearchCatalogProvider = FutureProvider.autoDispose<KikoSearchCatalog>(
  (ref) async {
    final api = ref.watch(kikoeruApiServiceProvider);
    var failures = 0;
    Future<List<KikoSearchSuggestion>> load(
      SearchType type,
      Future<List<dynamic>> Function() fetch,
    ) async {
      try {
        final data = await fetch();
        return data
            .whereType<Map>()
            .where((entry) => entry['id'] != null)
            .map(
              (entry) => KikoSearchSuggestion(
                type: type,
                id: entry['id'] as Object,
                name: (entry['name'] ?? entry['title'] ?? '').toString(),
              ),
            )
            .where((item) => item.name.isNotEmpty)
            .toList();
      } catch (_) {
        failures++;
        return [];
      }
    }

    final groups = await Future.wait([
      load(SearchType.tag, api.getAllTags),
      load(SearchType.va, api.getAllVas),
      load(SearchType.circle, api.getAllCircles),
    ]);
    if (failures == 3) throw Exception('Search suggestions unavailable');
    return KikoSearchCatalog(groups.expand((items) => items).toList());
  },
);

class KikoSearchField extends ConsumerStatefulWidget {
  const KikoSearchField({
    super.key,
    this.initialText = '',
    this.initialKeyword,
    this.showSearchButton = false,
    required this.onSearch,
  });
  final String initialText;
  final String? initialKeyword;
  final bool showSearchButton;
  final ValueChanged<KikoSearchQuery> onSearch;
  @override
  ConsumerState<KikoSearchField> createState() => _KikoSearchFieldState();
}

class _KikoSearchFieldState extends ConsumerState<KikoSearchField> {
  late final _controller = TextEditingController(text: widget.initialText);
  final _focus = FocusNode();
  late String _lastInput = widget.initialText;
  List<KikoSearchSelection> _selections = [];
  bool _restored = false;

  void _inputChanged(String value) {
    var prefix = 0;
    while (prefix < _lastInput.length &&
        prefix < value.length &&
        _lastInput[prefix] == value[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < _lastInput.length - prefix &&
        suffix < value.length - prefix &&
        _lastInput[_lastInput.length - suffix - 1] ==
            value[value.length - suffix - 1]) {
      suffix++;
    }
    final oldEnd = _lastInput.length - suffix;
    final delta = value.length - _lastInput.length;
    _selections = _selections.expand((s) {
      if (s.end <= prefix) return [s];
      if (s.start >= oldEnd) {
        return [
          KikoSearchSelection(s.start + delta, s.end + delta, s.suggestion),
        ];
      }
      return <KikoSearchSelection>[];
    }).toList();
    _lastInput = value;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final catalog =
        ref.read(kikoSearchCatalogProvider).valueOrNull ??
        const KikoSearchCatalog([]);
    _focus.unfocus();
    widget.onSearch(
      catalog.compile(
        text,
        Localizations.localeOf(context),
        selections: _selections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(kikoSearchCatalogProvider);
    final locale = Localizations.localeOf(context);
    if (!_restored && catalog.hasValue) {
      _restored = true;
      if (_lastInput == widget.initialText && widget.initialKeyword != null) {
        _selections = catalog.requireValue.restoreSelections(
          _lastInput,
          widget.initialKeyword!,
          locale,
        );
      }
    }
    final field = LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<KikoSearchSuggestion>(
        textEditingController: _controller,
        focusNode: _focus,
        displayStringForOption: (option) =>
            (catalog.valueOrNull ?? const KikoSearchCatalog([])).complete(
              _lastInput,
              option,
              locale,
            ),
        onSelected: (option) {
          final start = (catalog.valueOrNull ?? const KikoSearchCatalog([]))
              .fragmentStart(_lastInput, locale, suggestion: option);
          _selections.removeWhere((s) => s.end > start);
          _selections.add(
            KikoSearchSelection(start, _controller.text.length, option),
          );
          _lastInput = _controller.text;
          setState(() {});
        },
        optionsBuilder: (value) async {
          try {
            return (await ref.read(
              kikoSearchCatalogProvider.future,
            )).suggest(value.text, locale);
          } catch (_) {
            return [];
          }
        },
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: options
                      .map(
                        (option) => ListTile(
                          dense: true,
                          leading: Icon(
                            option.exclude
                                ? Icons.remove_circle_outline
                                : switch (option.type) {
                                    SearchType.tag => Icons.label_outline,
                                    SearchType.va => Icons.person_outline,
                                    _ => Icons.group_outlined,
                                  },
                          ),
                          title: Text(option.display(locale)),
                          subtitle: Text(option.type.localizedLabel(context)),
                          onTap: () => onSelected(option),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        fieldViewBuilder: (context, controller, focus, submit) => TextField(
          controller: controller,
          focusNode: focus,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          onChanged: _inputChanged,
          decoration: InputDecoration(
            hintText: locale.languageCode == 'zh'
                ? 'RJ号/关键词/标签/声优/社团'
                : 'RJ / keyword / tag / VA / circle',
            prefixIcon: IconButton(
              tooltip: S.of(context).search,
              icon: const Icon(Icons.search),
              onPressed: _submit,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (catalog.hasError)
                  IconButton(
                    tooltip: S.of(context).retry,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(kikoSearchCatalogProvider),
                  ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: S.of(context).clear,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _lastInput = '';
                      _selections.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
          ),
        ),
      ),
    );
    if (!widget.showSearchButton) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(80, 56)),
          child: Text(S.of(context).search),
        ),
      ],
    );
  }
}
