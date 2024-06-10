import 'package:flutter/material.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';

class FacetList extends StatefulWidget {
  const FacetList({
    required this.facetState,
    required this.filterState,
    required this.attribute,
    super.key,
  });

  final FacetState facetState;
  final String attribute;
  final Map<String, Set<String>> filterState;
  @override
  State<FacetList> createState() => _FacetListState();
}

class _FacetListState extends State<FacetList> {
  @override
  Widget build(BuildContext context) {
    final FacetCount facetList = widget.facetState.facetCounts
        .firstWhere((facetList) => facetList.fieldName == widget.attribute);

    final thisFilterState = widget.filterState[widget.attribute] ?? {};

    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: facetList.counts.length,
        itemBuilder: (_, idx) {
          final facet = facetList.counts[idx];
          final value = facet.value;

          return CheckboxListTile(
            value: thisFilterState.contains(value),
            title: Text("${facet.value} ${facet.count}"),
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
            },
          );
        });
  }
}
