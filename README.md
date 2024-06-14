<h1>
 🏀 Search NBA players' stats, powered by Typesense & flutter
</h1>
This search experience is powered by <a href="https://typesense.org" target="_blank">Typesense</a> which is
a blazing-fast, <a href="https://github.com/typesense/typesense" target="_blank">open source</a> typo-tolerant
search-engine. It is an open source alternative to Algolia and an easier-to-use alternative to ElasticSearch.<br/>
<br/>
This demo uses the <a href="https://github.com/typesense/typesense-dart" target="_blank">typesense-dart</a> client and flutter <a href="https://pub.dev/packages/infinite_scroll_pagination" target="_blank">infinite_scroll_pagination</a>.
The dataset is available on <a href="https://www.kaggle.com/datasets/justinas/nba-players-data" target="_blank">Kaggle</a>.

## Project Structure

```bash
├── cli/
│   ├── data/
│   │   └── nba_players.jsonl
│   ├── compose.yml
│   └── index_typesense.dart # index data from nba_players.jsonl into typesense server
└── src/
    ├── models/
    │   └── ...
    ├── widgets/
    │   └── ...
    ├── utils/
    │   └── typesense.dart # typesense client config
    └── main.dart # nba players search
```

## Development

To run this project locally, make sure you have flutter SDK installed:

```shell
cd cli
flutter pub get
#Start typesense server
docker compose up

#Index data into typesense
dart index_typesense.dart
```

Start developing
```shell
flutter pub get
flutter run --dart-define-from-file=.env
```

## Environment

Set env variables in `.env` file to point the app to the Typesense Cluster

```env
TYPESENSE_HOST=localhost # use your internet IPv4 address when developing on mobile
TYPESENSE_PORT=8108
TYPESENSE_PROTOCOL=http
TYPESENSE_SEARCH_ONLY_API_KEY=xyz
```

Only for indexing:

```env
TYPESENSE_ADMIN_API_KEY=xyz
FORCE_REINDEX=false
```
