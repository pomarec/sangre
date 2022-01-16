import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart';
import 'package:json_patch/json_patch.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sangre/sangre.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../env.dart';

void main() async {
  HttpServer? server;

  setUp(() async {
    server = await setupServer();
  });

  group('User list', () {
    Stream? usersStream;

    setUp(() async {
      usersStream = WebSocketChannel.connect(Uri.parse(
        'ws://$realtimeServerAddress:${server?.port ?? 4000}/ws/users',
      )).stream.cast<String>().map(json.decode);
    });

    test('Retrieve', () async {
      expect(
        usersStream,
        emitsInOrder([_usersBeforeAdd]),
      );
    });

    test('Retrieve and add user', () async {
      final newUserName = randomString();
      await get(Uri.parse(
        "http://$realtimeServerAddress:${server?.port ?? 4000}/addUser?name=$newUserName",
      ));

      expect(
        usersStream,
        emitsInOrder([
          _usersBeforeAdd,
          [
            ..._usersBeforeAdd,
            {
              'id': 4,
              'name': newUserName,
              'parent_id': 1,
              'parent': {'id': 1, 'name': 'omar', 'parent_id': 0}
            }
          ]
        ]),
      );
    });
  });

  group('User list diffed', () {
    Stream _buildUsersStream([int lastRevision = 0, List? lastUsers]) =>
        WebSocketChannel.connect(Uri.parse(
          'ws://$realtimeServerAddress:${server?.port ?? 4000}/ws/users-diffed?from=$lastRevision',
        )).stream.cast<String>().doOnData(print).map(json.decode).foldStream(
          {'revision': lastRevision, 'users': lastUsers ?? []},
          (previous, diffs) => {
            'revision': diffs['revision'],
            'users': JsonPatch.apply(
              previous['users'],
              (diffs['diffs'] as List).cast<Map<String, dynamic>>(),
              strict: false,
            ),
          },
        );

    Stream? usersStream;

    setUp(() async {
      usersStream = _buildUsersStream();
    });

    test('Retrieve', () async {
      expect(
        usersStream?.map((e) => e['users']),
        emitsInOrder([_usersBeforeAdd]),
      );
    });

    test('Retrieve and add user', () async {
      final newUserName = randomString();
      await get(Uri.parse(
        "http://$realtimeServerAddress:${server?.port ?? 4000}/addUser?name=$newUserName",
      ));

      expect(
        usersStream?.map((e) => e['users']),
        emitsInOrder([
          _usersBeforeAdd,
          [
            ..._usersBeforeAdd,
            {
              'id': 4,
              'name': newUserName,
              'parent_id': 1,
              'parent': {'id': 1, 'name': 'omar', 'parent_id': 0}
            }
          ]
        ]),
      );
    });

    test('Retrieve and add user with history', () async {
      final lastData = await usersStream?.first;

      expect(lastData['revision'], equals(1));
      expect(lastData['users'], equals(_usersBeforeAdd));

      final newUserName = randomString();
      await get(Uri.parse(
        "http://$realtimeServerAddress:${server?.port ?? 4000}/addUser?name=$newUserName",
      ));

      final newUsersStream = _buildUsersStream(
        lastData['revision'],
        lastData['users'],
      );

      expect(
        newUsersStream.map((e) => e['users']),
        emitsInOrder([
          [
            ..._usersBeforeAdd,
            {
              'id': 4,
              'name': newUserName,
              'parent_id': 1,
              'parent': {'id': 1, 'name': 'omar', 'parent_id': 0}
            }
          ]
        ]),
      );
    });
  });

  // test('Just run web server', () async {
  //   await Future.delayed(Duration(hours: 10000));
  // }, timeout: Timeout.none);
}

Future<HttpServer> setupServer() async {
  // Setup db & realtime clients
  var postgresClient = PostgreSQLConnection(
    postgresServerAddress,
    5432,
    "tests",
    username: "postgres",
    password: "example",
  );
  final realtimeClient =
      RealtimeClient('ws://$realtimeServerAddress:4000/socket');
  await postgresClient.open();
  realtimeClient.connect();

  // Setup db data
  final sql = """
      DROP TABLE IF EXISTS "users";
      CREATE TABLE "public"."users" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL,
          "parent_id" integer NOT NULL
      ) WITH (oids = false);

      ALTER TABLE "users" REPLICA IDENTITY FULL;

      INSERT INTO "users" ("id", "name", "parent_id") VALUES
      (0,	'fred', 1),
      (1,	'omar', 0),
      (2,	'pataf', 0),
      (3,	'skavinski', 0);
    """;
  await postgresClient.execute(sql);

  // Setup nodes
  final usersDBSource =
      await PostgresTableSource('users', postgresClient, realtimeClient);
  final usersWithParent = await JoinOneToOne(
    usersDBSource,
    (e) => e['parent_id'],
    usersDBSource,
    (e) => e['id'],
    (e, v) => e['parent'] = v,
  );

  // Setup api server
  final app = Alfred()
    ..sangre('/users', usersWithParent, postgresClient)
    ..get('/addUser', (req, res) async {
      final name = req.uri.queryParameters['name'];
      await postgresClient.execute("""
          INSERT INTO "users" ("id", "name", "parent_id") VALUES
          (${usersWithParent.stream.value.length},	'${name ?? randomString()}', 1);
        """);
    });

  // app.printRoutes();
  return await app.listen();
}

final _usersBeforeAdd = [
  {
    "id": 0,
    "name": "fred",
    "parent_id": 1,
    "parent": {"id": 1, "name": "omar", "parent_id": 0}
  },
  {
    "id": 1,
    "name": "omar",
    "parent_id": 0,
    "parent": {"id": 0, "name": "fred", "parent_id": 1}
  },
  {
    "id": 2,
    "name": "pataf",
    "parent_id": 0,
    "parent": {"id": 0, "name": "fred", "parent_id": 1}
  },
  {
    "id": 3,
    "name": "skavinski",
    "parent_id": 0,
    "parent": {"id": 0, "name": "fred", "parent_id": 1}
  }
];
