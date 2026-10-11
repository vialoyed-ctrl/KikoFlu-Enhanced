import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/utils/subtitle_filter.dart';

const _onlineSubtitleWork = Work(
  id: 1,
  title: 'online subtitle',
  hasSubtitle: true,
);

const _localSubtitleWork = Work(
  id: 2,
  title: 'local subtitle',
  hasSubtitle: false,
);

const _noSubtitleWork = Work(
  id: 3,
  title: 'no subtitle',
  hasSubtitle: false,
);

void main() {
  test('subtitle filter cycles through available states', () {
    expect(SubtitleFilterMode.all.next, SubtitleFilterMode.withSubtitles);
    expect(SubtitleFilterMode.withSubtitles.next, SubtitleFilterMode.all);
  });

  test('legacy without-subtitles value falls back to all works', () {
    expect(SubtitleFilterMode.fromValue(2), SubtitleFilterMode.all);
  });

  test('detects online and local library subtitles', () {
    const localSubtitleIds = {2};

    expect(workHasAnySubtitle(_onlineSubtitleWork, localSubtitleIds), true);
    expect(workHasAnySubtitle(_localSubtitleWork, localSubtitleIds), true);
    expect(workHasAnySubtitle(_noSubtitleWork, localSubtitleIds), false);
  });

  test('filters works by subtitle mode', () {
    const works = [
      _onlineSubtitleWork,
      _localSubtitleWork,
      _noSubtitleWork,
    ];
    const localSubtitleIds = {2};

    expect(
      filterWorksBySubtitleMode(
        works,
        localSubtitleIds,
        SubtitleFilterMode.all.value,
      ).map((work) => work.id),
      [1, 2, 3],
    );
    expect(
      filterWorksBySubtitleMode(
        works,
        localSubtitleIds,
        SubtitleFilterMode.withSubtitles.value,
      ).map((work) => work.id),
      [1, 2],
    );
    expect(
        filterWorksBySubtitleMode(works, localSubtitleIds, 2).map(
          (work) => work.id,
        ),
        [1, 2, 3]);
  });
}
