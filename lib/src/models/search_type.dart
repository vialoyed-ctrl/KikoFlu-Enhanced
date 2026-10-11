enum SearchType { tag, va, circle }

enum AgeRating {
  all('', '全部'),
  general('general', '全年龄'),
  r15('r15', 'R-15'),
  adult('adult', '成人向');

  const AgeRating(this.value, this.label);

  final String value;
  final String label;
}

enum SalesRange {
  all(0, '全部'),
  over100(100, '100+'),
  over300(300, '300+'),
  over500(500, '500+'),
  over700(700, '700+'),
  over1000(1000, '1000+'),
  over2000(2000, '2000+');

  const SalesRange(this.value, this.label);

  final int value;
  final String label;
}

class SearchFilters {
  const SearchFilters({
    this.minRate = 0,
    this.ageRating = AgeRating.all,
    this.salesRange = SalesRange.all,
  });
  final double minRate;
  final AgeRating ageRating;
  final SalesRange salesRange;

  String buildSearchKeyword() => [
    if (minRate > 0) '\$rate:${minRate.toInt()}\$',
    if (ageRating.value.isNotEmpty) '\$age:${ageRating.value}\$',
    if (salesRange.value > 0) '\$sell:${salesRange.value}\$',
  ].join(' ');
}
