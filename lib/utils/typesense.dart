// ignore_for_file: constant_identifier_names
import 'package:typesense/typesense.dart';

const TYPESENSE_PROTOCOL =
    String.fromEnvironment('TYPESENSE_PROTOCOL', defaultValue: 'http');

const TYPESENSE_HOST = String.fromEnvironment(
  'TYPESENSE_HOST',
  defaultValue: '192.168.1.8', // replace with your wifi IPV4 address)
);

const TYPESENSE_PORT =
    int.fromEnvironment('TYPESENSE_PORT', defaultValue: 8108);

const TYPESENSE_SEARCH_ONLY_API_KEY = String.fromEnvironment(
    'TYPESENSE_SEARCH_ONLY_API_KEY',
    defaultValue: 'xyz');

final typesenseClient = Client(Configuration(
  TYPESENSE_SEARCH_ONLY_API_KEY,
  nodes: {
    Node.withUri(
      Uri(
        scheme: TYPESENSE_PROTOCOL,
        host: TYPESENSE_HOST,
        port: TYPESENSE_PORT,
      ),
    ),
  },
  numRetries: 3, // A total of 4 tries (1 original try + 3 retries)
  connectionTimeout: const Duration(seconds: 2),
));
