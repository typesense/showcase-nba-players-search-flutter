<h1>
 🏀 Search NBA players' stats, powered by Typesense & flutter
</h1>

This demo uses the <a href="https://github.com/typesense/typesense-dart" target="_blank">typesense-dart</a> client and <a href="https://pub.dev/packages/infinite_scroll_pagination" target="_blank">infinite_scroll_pagination</a> for flutter.
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
#Start typesense server
npm run start:typesense # or: docker compose up

#Index data into typesense
npm run index:typesense
```

Open http://localhost:5173 to see the app ✌️

## Environment

Set env variables in `.env` file to point the app to the Typesense Cluster

```env
TYPESENSE_HOST=localhost #use your internet IPv4 address when developing on mobile
TYPESENSE_PORT=8108
TYPESENSE_PROTOCOL=http
TYPESENSE_SEARCH_ONLY_API_KEY=xyz
```

Only for indexing:

```env
TYPESENSE_ADMIN_API_KEY=xyz
FORCE_REINDEX=false
```
