import 'package:flutter/material.dart';
import '../models/nba_player_search_facet.dart';

class FacetList extends StatefulWidget {
  const FacetList({
    required this.facetCounts,
    required this.filterState,
    required this.attribute,
    required this.handleOnChange,
    this.showMoreLimit = 8,
    super.key,
  });

  final List<FacetCount> facetCounts;
  final String attribute;
  final void Function(int idx) handleOnChange;
  final Map<String, Set<String>> filterState;
  final int showMoreLimit;

  @override
  State<FacetList> createState() => _FacetCountstate();
}

class _FacetCountstate extends State<FacetList> {
  bool _isShowMore = false;

  @override
  Widget build(BuildContext context) {
    final FacetCount facetList = widget.facetCounts
        .firstWhere((facetList) => facetList.fieldName == widget.attribute);

    final thisFilterState = widget.filterState[widget.attribute]!;
    int facetLength = facetList.counts.length;

    bool isAbleToShowMore = facetLength > widget.showMoreLimit;

    return SliverMainAxisGroup(
      slivers: [
        SliverList(
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
          },
              childCount: _isShowMore || !isAbleToShowMore
                  ? facetLength
                  : widget.showMoreLimit),
        ),
        isAbleToShowMore
            ? SliverToBoxAdapter(
                child: Padding(
                padding: const EdgeInsets.only(
                    top: 12, bottom: 12, left: 80, right: 80),
                child: OutlinedButton(
                  child: Text(
                    _isShowMore ? 'Show less' : 'Show more',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => setState(() {
                    _isShowMore = !_isShowMore;
                  }),
                ),
              ))
            : const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.only(
                        top: 12, bottom: 12, left: 80, right: 80)))
      ],
    );
  }
}
