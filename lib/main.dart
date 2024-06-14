import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';
import 'package:showcase_typesense_flutter/utils/populate_filter_by.dart';
import 'package:showcase_typesense_flutter/widgets/facet_list.dart';
import 'package:showcase_typesense_flutter/widgets/nba_player_list_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/typesense.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Color(0xffd90368),
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Color.fromARGB(255, 255, 253, 246),
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Search NBA players\' stats'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  final _searchInputController = TextEditingController();

  String query = '*';

  static const _pageSize = 20;

  final _pagingController = PagingController<int, NBAPlayer>(firstPageKey: 1);

  final _facetState = FacetState();

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  void search() => setState(() {
        query = _searchInputController.text;
        _facetState.filterBy = '';
        _facetState.filterState.clear();
        _pagingController.refresh();
      });

  (Map<String, dynamic>, Map<String, int?>) populateSearchRequests() {
    final searchRequests = {
      (_facetState.filterBy, 'team_abbreviation,country,season'),
    };

    final Map<String, int?> keyIndexPairs = {};

    _facetState.filterState.forEach((key, val) {
      if (val.isEmpty) {
        keyIndexPairs[key] = null;
      } else {
        final copy = {..._facetState.filterState};
        copy.remove(key);
        final filterBy = populateFilterBy(copy);
        searchRequests.add((filterBy, key));
        keyIndexPairs[key] = searchRequests.length - 1;
      }
    });

    return (
      {
        'searches': searchRequests.map((item) {
          final (filterBy, key) = item;
          return {
            'filter_by': filterBy,
            'facet_by': key,
          };
        }).toList(),
      },
      keyIndexPairs
    );
  }

  Future<void> _fetchPage(pageKey) async {
    try {
      final (searchRequests, keyIndexPairs) = populateSearchRequests();

      final commonSearchParams = {
        'collection': 'nba_players',
        'q': query,
        'query_by': 'player_name',
        'page': '$pageKey',
        'per_page': '$_pageSize',
        'max_facet_values': '99',
      };

      final res = await typesenseClient.multiSearch
          .perform(searchRequests, queryParams: commonSearchParams);

      final mainResult = res['results'][0];

      final newItems = mainResult['hits']
          .map<NBAPlayer>((item) => NBAPlayer.fromJson(item['document']))
          .toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }

      setState(() {
        if (_facetState.filterState.isEmpty) {
          _facetState.facetCounts =
              mainResult['facet_counts'].map<FacetCount>((item) {
            final facetCount = FacetCount.fromJson(item);
            _facetState.filterState[facetCount.fieldName] = {};
            return facetCount;
          }).toList();
        } else {
          keyIndexPairs.forEach((key, value) {
            final index = _facetState.facetCounts
                .indexWhere((item) => item.fieldName == key);
            if (value == null) {
              _facetState.facetCounts[index] = mainResult['facet_counts']
                  .map<FacetCount>((item) => FacetCount.fromJson(item))
                  .firstWhere((item) => item.fieldName == key);
            } else {
              var newFacet =
                  FacetCount.fromJson(res['results'][value]['facet_counts'][0]);
              final newFacetValues = newFacet.counts.map((item) => item.value);
              final prevSelectedFacetItems = [];
              final prevFacet = _facetState.facetCounts[index].counts;

              for (var i = 0; i < prevFacet.length; i++) {
                final prevFacetValue = prevFacet[i].value;
                final isSelectedFacet =
                    _facetState.filterState[key]!.contains(prevFacetValue);
                final existInNewFacets =
                    newFacetValues.contains(prevFacetValue);
                if (!isSelectedFacet) {
                  continue;
                }
                if (!existInNewFacets) {
                  prevFacet[i].count = 0;
                } else {
                  newFacet.counts
                      .removeWhere((item) => item.value == prevFacetValue);
                }
                prevSelectedFacetItems.add(prevFacet[i]);
              }
              newFacet.counts = [...prevSelectedFacetItems, ...newFacet.counts];
              _facetState.facetCounts[index] = newFacet;
            }
          });
        }
      });
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      endDrawer: Drawer(
        child: _filters(context),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: appBar(context),
      ),
      body: appBody(context),
    );
  }

  Center appBody(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: TextField(
                controller: _searchInputController,
                onSubmitted: (String value) => search(),
                decoration: InputDecoration(
                  fillColor: Theme.of(context).colorScheme.surface,
                  filled: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                        top: 12, bottom: 12, left: 14, right: 14),
                    child: SvgPicture.asset('assets/icons/Search.svg'),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      icon: SvgPicture.asset('assets/icons/Filter.svg'),
                      onPressed: () => _key.currentState!.openEndDrawer(),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(width: 1.5),
                  ),
                  hintText: 'Type in an NBA player name...',
                ),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: _infiniteHitsListView(context),
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 12,
              ),
              children: [
                const TextSpan(text: 'powered by '),
                TextSpan(
                  text: 'Typesense',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      openLink('https://typesense.org/');
                    },
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Flutter',
                  style: const TextStyle(
                    color: Color(0xff0468d7),
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      openLink('https://flutter.dev/');
                    },
                ),
              ],
            ),
          )
        ],
      ),
      toolbarHeight: 100,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: <Widget>[Container()], // this will hide endDrawer hamburger icon
    );
  }

  Widget _filters(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        body: Builder(builder: (context) {
          if (_facetState.facetCounts.isEmpty) {
            return const Center(child: Text('No data'));
          }

          final facetCounts = _facetState.facetCounts;

          void handleOnChange(idx) {
            setState(() {
              _facetState.filterBy = populateFilterBy(_facetState.filterState);
              _pagingController.refresh();
            });
          }

          filterTitle(String tilte) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    tilte,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomScrollView(
              slivers: [
                filterTitle('Team'),
                FacetList(
                  facetCounts: facetCounts,
                  attribute: 'team_abbreviation',
                  filterState: _facetState.filterState,
                  handleOnChange: handleOnChange,
                ),
                filterTitle('Season'),
                FacetList(
                  facetCounts: facetCounts,
                  attribute: 'season',
                  filterState: _facetState.filterState,
                  handleOnChange: handleOnChange,
                ),
                filterTitle('Player\'s nationality'),
                FacetList(
                  facetCounts: facetCounts,
                  attribute: 'country',
                  filterState: _facetState.filterState,
                  handleOnChange: handleOnChange,
                  showMoreLimit: 6,
                ),
              ],
            ),
          );
          //   },
          // );
        }),
      );

  Widget _infiniteHitsListView(BuildContext context) => RefreshIndicator(
        onRefresh: () => Future.sync(
          () => _pagingController.refresh(),
        ),
        child: PagedListView.separated(
          // 4
          pagingController: _pagingController,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (context, index) => const SizedBox(
            height: 16,
          ),
          builderDelegate: PagedChildBuilderDelegate<NBAPlayer>(
            itemBuilder: (context, item, index) =>
                NbaPlayerListItem(player: item),
            noMoreItemsIndicatorBuilder: (context) => const Center(
                child: Text(
              'That\'s all!',
            )),
            noItemsFoundIndicatorBuilder: (context) => const Center(
                child: Text(
              'No results found!',
            )),
          ),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    _searchInputController.dispose();
    super.dispose();
  }
}

Future<void> openLink(String url) async {
  final Uri uri = Uri.parse(url);
  await launchUrl(uri);
}
