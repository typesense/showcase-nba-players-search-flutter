class FacetCounts {
  FacetCounts({
    required this.facetCounts,
  });

  final List<FacetCount> facetCounts;

  factory FacetCounts.fromSearchResponse(Map<String, dynamic> json) =>
      FacetCounts(
        facetCounts: json['facet_counts']
            .map<FacetCount>((item) => FacetCount.fromJson(item))
            .toList(),
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
  });

  final int count;
  final String value;

  factory FacetCountItem.fromJson(Map<String, dynamic> json) =>
      FacetCountItem(count: json['count'], value: json['value']);
}
