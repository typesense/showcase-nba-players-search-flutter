// ignore_for_file: avoid_print, constant_identifier_names

import 'package:typesense/typesense.dart';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {
  const collectionName = 'nba_players';

  var env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);

  final typesenseClient = Client(Configuration(
    env['TYPESENSE_ADMIN_API_KEY'] ?? 'asd',
    nodes: {
      Node.withUri(
        Uri(
          scheme: env['TYPESENSE_PROTOCOL'] ?? 'asd',
          host: env['TYPESENSE_HOST'] ?? 'asd',
          port: int.parse(env['TYPESENSE_PORT'] ?? 'asd'),
        ),
      ),
    },
    numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
    connectionTimeout: const Duration(seconds: 2),
  ));

  try {
    await typesenseClient.collection(collectionName).retrieve();
    print('Found existing collection of $collectionName');
    if (env['FORCE_REINDEX'] != 'true') {
      return print('FORCE_REINDEX is not enabled. Canceling...');
    }
    print('Deleting collection');
    await typesenseClient.collection(collectionName).delete();
  } catch (e) {
    print(e);
  }

  print('Creating schema...');

  await typesenseClient.collections.create(Schema(
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
    final returnData = await typesenseClient
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
