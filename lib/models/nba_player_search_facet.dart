class FacetCounts {
  List<FacetCount> facetCounts = [];
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
