import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import 'package:typesense/typesense.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

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
        colorScheme: const ColorScheme.light(),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
                    hintText: 'Search NBA player name...'),
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
            itemBuilder: (context, item, index) => ListTile(
              title: Text(item.playerName),
            ),
            // firstPageErrorIndicatorBuilder: (context) => ErrorIndicator(
            //   error: _pagingController.error,
            //   onTryAgain: () => _pagingController.refresh(),
            // ),
            noItemsFoundIndicatorBuilder: (context) =>
                const Text('Could not find players!'),
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
