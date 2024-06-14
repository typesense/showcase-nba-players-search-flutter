class FacetState {
  List<FacetCount> facetCounts = [];
  Map<String, Set<String>> filterState =
      {}; // eg {'team_abbreviation': {'CLE','LAL'}}
  String filterBy = ''; //eg: team_abbreviation:=[LAC] && season:=[2017-18]
}

class FacetCount {
  FacetCount({
    required this.counts,
    required this.fieldName,
  });

  List<FacetCountItem> counts;
  final String fieldName;

  factory FacetCount.fromJson(Map<String, dynamic> json) => FacetCount(
        counts: json['counts']
            .map<FacetCountItem>((item) => FacetCountItem.fromJson(item))
            .toList(),
        fieldName: json['field_name'],
      );
}

class FacetCountItem {
  FacetCountItem({
    required this.count,
    required this.value,
  });

  int count;
  final String value;

  factory FacetCountItem.fromJson(Map<String, dynamic> json) =>
      FacetCountItem(count: json['count'], value: json['value']);
}
