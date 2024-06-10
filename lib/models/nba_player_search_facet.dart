class FacetState {
  FacetState({
    required this.facetCounts,
    required this.filterBy,
  });

  final List<FacetCount> facetCounts;
  final String filterBy;

  factory FacetState.fromSearchResponse(Map<String, dynamic> json, filterBy) =>
      FacetState(
        facetCounts: json['facet_counts']
            .map<FacetCount>((item) => FacetCount.fromJson(item))
            .toList(),
        filterBy: filterBy,
      );
}

class FacetCount {
  FacetCount({
    required this.counts,
    required this.fieldName,
  });

  final List<FacetCountItem> counts;
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
    required this.isSelected,
  });

  final int count;
  final String value;
  bool isSelected;

  factory FacetCountItem.fromJson(Map<String, dynamic> json) => FacetCountItem(
      count: json['count'], value: json['value'], isSelected: false);
}
