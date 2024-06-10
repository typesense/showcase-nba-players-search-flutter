import 'package:flutter/material.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';

class FacetList extends StatefulWidget {
  const FacetList({
    required this.facetState,
    required this.attribute,
    super.key,
  });

  final FacetState facetState;
  final String attribute;
  @override
  State<FacetList> createState() => _FacetListState();
}

class _FacetListState extends State<FacetList> {
  @override
  Widget build(BuildContext context) {
    final FacetCount facetList = widget.facetState.facetCounts
        .firstWhere((facetList) => facetList.fieldName == widget.attribute);

    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: facetList.counts.length,
        itemBuilder: (_, idx) {
          final facet = facetList.counts[idx];
          return CheckboxListTile(
            value: facet.isSelected,
            title: Text("${facet.value} ${facet.count}"),
            onChanged: (_) {
              setState(() {
                facet.isSelected = !facet.isSelected;
              });
            },
          );
        });
  }
}
