import 'package:flutter/material.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';

class FacetList extends StatefulWidget {
  const FacetList({
    required this.facetCounts,
    required this.filterState,
    required this.attribute,
    required this.handleOnChange,
    super.key,
  });

  final List<FacetCount> facetCounts;
  final String attribute;
  final void Function(int idx) handleOnChange;
  final Map<String, Set<String>> filterState;
  @override
  State<FacetList> createState() => _FacetCountstate();
}

class _FacetCountstate extends State<FacetList> {
  @override
  Widget build(BuildContext context) {
    final FacetCount facetList = widget.facetCounts
        .firstWhere((facetList) => facetList.fieldName == widget.attribute);

    final thisFilterState = widget.filterState[widget.attribute]!;

    return SliverList(
        delegate: SliverChildBuilderDelegate((_, idx) {
      final facet = facetList.counts[idx];
      final value = facet.value;

      return CheckboxListTile(
        value: thisFilterState.contains(value),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${facet.value} ',
                style: const TextStyle(fontSize: 14),
              ),
              TextSpan(
                text: '${facet.count}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        onChanged: (_) {
          if (thisFilterState.contains(value)) {
            thisFilterState.remove(value);
          } else {
            thisFilterState.add(value);
          }
          widget.handleOnChange(idx);
        },
      );
    }, childCount: facetList.counts.length));
  }
}
