import 'package:flutter/material.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';

class FacetList extends StatefulWidget {
  const FacetList({
    required this.facetCounts,
    required this.filterState,
    required this.attribute,
    required this.onChanged,
    super.key,
  });

  final FacetCounts facetCounts;
  final String attribute;
  final void Function(bool?) onChanged;
  final Map<String, Set<String>> filterState;
  @override
  State<FacetList> createState() => _FacetCountstate();
}

class _FacetCountstate extends State<FacetList> {
  @override
  Widget build(BuildContext context) {
    final FacetCount facetList = widget.facetCounts.facetCounts
        .firstWhere((facetList) => facetList.fieldName == widget.attribute);

    final thisFilterState = widget.filterState[widget.attribute] ?? {};

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
          setState(() {
            final prevValues = widget.filterState[widget.attribute] ?? {};
            if (prevValues.contains(value)) {
              prevValues.remove(value);
            } else {
              prevValues.add(value);
            }
            widget.filterState[widget.attribute] = prevValues;
          });
          widget.onChanged(_);
        },
      );
    }, childCount: facetList.counts.length));
  }
}
