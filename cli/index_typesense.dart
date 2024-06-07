// ignore_for_file: avoid_print
import 'package:typesense/typesense.dart';
import 'dart:io';

void main() async {
  const collectionName = 'nba_players';
  final config = Configuration(
    // Api key
    'xyz',
    nodes: {
      Node.withUri(
        Uri(
          scheme: 'http',
          host: 'localhost',
          port: 8108,
        ),
      ),
    },
    numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
    connectionTimeout: const Duration(seconds: 2),
  );

  final client = Client(config);

  try {
    await client.collection(collectionName).retrieve();
    print('Found existing collection of $collectionName');
    print('Deleting collection');
    await client.collection(collectionName).delete();
  } catch (e) {
    print(e);
  }

  print('Creating schema...');

  await client.collections.create(Schema(
    collectionName,
    {
      Field('player_name', type: Type.string),
      Field('team_abbreviation', type: Type.string, isFacetable: true),
      Field('country', type: Type.string, isFacetable: true),
      Field('season', type: Type.string, isFacetable: true),
    },
  ));

  print('Indexing data');

  final file = await getFile('data/nba_players.jsonl');
  try {
    final returnData = await client
        .collection(collectionName)
        .documents
        .importJSONL(file.readAsStringSync());

    print('Return data: $returnData');
  } catch (error) {
    print(error);
  }
}

Future<File> getFile(String relativePathToFile) async {
  final path = Directory.current.path;
  return File('$path/$relativePathToFile');
}
