import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import 'package:typesense/typesense.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import './utils/nba_team_color.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Typesense - Dart'),
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
  final _searchInputController = TextEditingController();

  String query = '*';
  int pageKey = 1;

  static const _pageSize = 20;

  final _pagingController = PagingController<int, NBAPlayer>(firstPageKey: 1);
  final config = Configuration(
    // Api key
    'xyz',
    nodes: {
      Node.withUri(
        Uri(
          scheme: 'http',
          host: '192.168.1.9',
          port: 8108,
        ),
      ),
    },
    numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
    connectionTimeout: const Duration(seconds: 2),
  );

  Client? client;

  @override
  void initState() {
    _searchInputController
        .addListener(() => print(_searchInputController.text));

    _pagingController.addPageRequestListener((pagingControllerPageKey) {
      pageKey = pagingControllerPageKey;
      _fetchPage();
    });
    client = Client(config);

    super.initState();
  }

  Future<void> _fetchPage() async {
    try {
      final searchParameters = {
        'q': query,
        'query_by': 'player_name',
        'page': '$pageKey',
        'per_page': '$_pageSize',
      };
      final res = await client
          ?.collection('nba_players')
          .documents
          .search(searchParameters);
      print(res);
      final newItems = res?['hits']
          .map<NBAPlayer>((item) => NBAPlayer.fromJson(item['document']))
          .toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      print(_pagingController);
    } catch (error) {
      print(error);
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                  margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: const Color(0xff1D1617).withOpacity(0.11),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ]),
                  child: TextField(
                    controller: _searchInputController,
                    onSubmitted: (String value) {
                      setState(() {
                        query = _searchInputController.text;
                        _pagingController.refresh();
                      });
                    },
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icons/Search.svg'),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Search NBA player name...',
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

  Widget _infiniteHitsListView(BuildContext context) => RefreshIndicator(
        onRefresh: () => Future.sync(
          // 2
          () => _pagingController.refresh(),
        ),
        // 3
        child: PagedListView.separated(
          // 4
          pagingController: _pagingController,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (context, index) => const SizedBox(
            height: 16,
          ),
          builderDelegate: PagedChildBuilderDelegate<NBAPlayer>(
            itemBuilder: (context, item, index) {
              final teamColor = colors[item.team]?['rgb'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              item.team,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Color.fromRGBO(
                                teamColor[0], teamColor[1], teamColor[2], 1),
                            padding: const EdgeInsets.all(0),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            item.playerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      MutedText(
                        item.season,
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      MutedText(
                          '${covertCMToFeet(item.height)} (${(item.height / 100).toStringAsFixed(2)}m) / ${(item.weight * 2.2046).round()}lbs (${item.weight.round()}kg)'),
                      Wrap(
                        spacing: 20,
                        children: [
                          Text('PTS: ${item.pts}'),
                          Text('REB: ${item.reb}'),
                          Text('AST: ${item.ast}'),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },

            // firstPageErrorIndicatorBuilder: (context) => ErrorIndicator(
            //   error: _pagingController.error,
            //   onTryAgain: () => _pagingController.refresh(),
            // ),
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

class MutedText extends Text {
  const MutedText(
    super.data, {
    super.key,
    style,
  }) : super(
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        );
}

covertCMToFeet(double n) {
  var realFeet = ((n * 0.393700) / 12);
  var feet = realFeet.floor();
  var inches = ((realFeet - feet) * 12).floor();
  return '$feet\'$inches"';
}
