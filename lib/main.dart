import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';
import 'package:showcase_typesense_flutter/utils/populate_filter_by.dart';
import 'package:showcase_typesense_flutter/widgets/facet_list.dart';
import 'package:showcase_typesense_flutter/widgets/nba_player_list_item.dart';
import 'package:typesense/typesense.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final GlobalKey<ScaffoldState> _key = GlobalKey(); // Create a key

  final _searchInputController = TextEditingController();

  String query = '*';

  static const _pageSize = 20;

  final _pagingController = PagingController<int, NBAPlayer>(firstPageKey: 1);

  final client = Client(Configuration(
    // Api key
    'xyz',
    nodes: {
      Node.withUri(
        Uri(
          scheme: 'http',
          host: '192.168.1.8', // replace with your wifi IPV4 address
          port: 8108,
        ),
      ),
    },
    numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
    connectionTimeout: const Duration(seconds: 2),
  ));

  final _facetState = FacetState();

  void search() => setState(() {
        query = _searchInputController.text;
        _facetState.filterBy = '';
        _facetState.filterState.clear();
        _pagingController.refresh();
      });

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  (Map<String, dynamic>, Map<String, int?>) populateSearchRequests() {
    final searchRequests = {
      _facetState.filterBy,
    };

    final Map<String, int?> keyIndexPairs = {};

    final emptyKeys = [];
    _facetState.filterState.forEach((key, value) {
      if (value.isEmpty) {
        emptyKeys.add(key);
        keyIndexPairs[key] = null;
      }
    });

    _facetState.filterState.removeWhere((k, v) => emptyKeys.contains(k));
    final keys = _facetState.filterState.keys;

    for (var i = 0; i < keys.length; i++) {
      final copy = {..._facetState.filterState};
      copy.remove(keys.elementAt(i));
      if (copy.isNotEmpty) {
        final req = populateFilterBy(copy);
        searchRequests.add(req);
        keyIndexPairs[keys.elementAt(i)] = i + 1;
      }
    }

    return (
      {
        'searches': searchRequests
            .map((item) => {
                  'filter_by': item,
                })
            .toList(),
      },
      keyIndexPairs
    );
  }

  Future<void> _fetchPage(pageKey) async {
    try {
      final (searchRequests, keyIndexPairs) = populateSearchRequests();

      print(keyIndexPairs);
      final commonSearchParams = {
        'collection': 'nba_players',
        'q': query,
        'query_by': 'player_name',
        'page': '$pageKey',
        'per_page': '$_pageSize',
        'facet_by': 'team_abbreviation,country,season',
        'max_facet_values': '99',
      };

      final res = await client.multiSearch
          .perform(searchRequests, queryParams: commonSearchParams);
      final newItems = res['results'][0]['hits']
          .map<NBAPlayer>((item) => NBAPlayer.fromJson(item['document']))
          .toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }

      if (_facetState.facetCounts.isEmpty) {
        setState(() {
          _facetState.facetCounts =
              res['results'][0]['facet_counts'].map<FacetCount>((item) {
            final facetCount = FacetCount.fromJson(item);
            _facetState.filterState[facetCount.fieldName] = {};
            return facetCount;
          }).toList();
        });
      } else {
        setState(() {
          keyIndexPairs.forEach((key, value) {
            final index = _facetState.facetCounts
                .indexWhere((item) => item.fieldName == key);

            if (value == null) {
              _facetState.facetCounts[index] = res['results'][0]['facet_counts']
                  .map<FacetCount>((item) => FacetCount.fromJson(item))
                  .firstWhere((item) => item.fieldName == key);
              _facetState.filterState[key] = {};
            } else {
              _facetState.facetCounts[index] = res['results'][value]
                      ['facet_counts']
                  .map<FacetCount>((item) => FacetCount.fromJson(item))
                  .firstWhere((item) => item.fieldName == key);
            }
          });
        });
      }
    } catch (error) {
      _pagingController.error = error;
      print(error);
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
      body: Center(
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

          void onChanged(_) {
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
                  onChanged: onChanged,
                ),
                filterTitle('Season'),
                FacetList(
                  facetCounts: facetCounts,
                  attribute: 'season',
                  filterState: _facetState.filterState,
                  onChanged: onChanged,
                ),
                filterTitle('Player\'s nationality'),
                FacetList(
                  facetCounts: facetCounts,
                  attribute: 'country',
                  filterState: _facetState.filterState,
                  onChanged: onChanged,
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
