import '../models/work.dart';

enum SubtitleFilterMode {
  all(0),
  withSubtitles(1);

  const SubtitleFilterMode(this.value);

  final int value;

  static SubtitleFilterMode fromValue(int value) {
    return SubtitleFilterMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => SubtitleFilterMode.all,
    );
  }

  SubtitleFilterMode get next {
    return switch (this) {
      SubtitleFilterMode.all => SubtitleFilterMode.withSubtitles,
      SubtitleFilterMode.withSubtitles => SubtitleFilterMode.all,
    };
  }

  bool get isActive => this != SubtitleFilterMode.all;
}

bool workHasAnySubtitle(Work work, Set<int> localSubtitleIds) {
  return work.hasSubtitle == true || localSubtitleIds.contains(work.id);
}

bool workMatchesSubtitleFilter(
  Work work,
  Set<int> localSubtitleIds,
  int subtitleFilter,
) {
  final mode = SubtitleFilterMode.fromValue(subtitleFilter);
  if (mode == SubtitleFilterMode.all) return true;

  final hasSubtitle = workHasAnySubtitle(work, localSubtitleIds);
  return switch (mode) {
    SubtitleFilterMode.all => true,
    SubtitleFilterMode.withSubtitles => hasSubtitle,
  };
}

List<Work> filterWorksBySubtitleMode(
  List<Work> works,
  Set<int> localSubtitleIds,
  int subtitleFilter,
) {
  return works.where((work) {
    return workMatchesSubtitleFilter(
      work,
      localSubtitleIds,
      subtitleFilter,
    );
  }).toList();
}
