import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import 'package:showcase_typesense_flutter/models/nba_player_search_facet.dart';
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
          host: '192.168.1.9', // replace with your wifi IPV4 address
          port: 8108,
        ),
      ),
    },
    numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
    connectionTimeout: const Duration(seconds: 2),
  ));
  Future<FacetCounts?>? _facetCounts;
  final Map<String, Set<String>> filterState = {};
  String filterBy = '';

  void search() => setState(() {
        query = _searchInputController.text;
        filterBy = '';
        filterState.clear();
        _pagingController.refresh();
      });

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(pageKey) async {
    try {
      final searchParameters = {
        'q': query,
        'query_by': 'player_name',
        'page': '$pageKey',
        'per_page': '$_pageSize',
        'facet_by': 'team_abbreviation,country,season',
        'max_facet_values': '99',
        'filter_by': filterBy,
      };
      final res = await client
          .collection('nba_players')
          .documents
          .search(searchParameters);

      final newItems = res['hits']
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
        _facetCounts = Future.value(FacetCounts.fromSearchResponse(res));
      });
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
      body: Flexible(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 14),
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
        body: FutureBuilder<FacetCounts?>(
            future: _facetCounts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Text('Loading...'));
              } else {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No data'));
                }

                final state = snapshot.data!;

                void onChanged(_) {
                  final filterItems = [];
                  filterState.forEach((key, value) {
                    if (value.isNotEmpty) {
                      filterItems.add('$key:=[${value.join(',')}]');
                    }
                  });
                  setState(() {
                    filterBy = filterItems.join(' && ');
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
                        facetCounts: state,
                        attribute: 'team_abbreviation',
                        filterState: filterState,
                        onChanged: onChanged,
                      ),
                      filterTitle('Season'),
                      FacetList(
                        facetCounts: state,
                        attribute: 'season',
                        filterState: filterState,
                        onChanged: onChanged,
                      ),
                      filterTitle('Player\'s nationality'),
                      FacetList(
                        facetCounts: state,
                        attribute: 'country',
                        filterState: filterState,
                        onChanged: onChanged,
                      ),
                    ],
                  ),
                );
                //   },
                // );
              }
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
