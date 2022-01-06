import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:http/http.dart';
import 'package:sangre/sangre.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../env.dart';
import '../utils.dart';

void main() async {
  HttpServer? server;

  setUp(() async {
    server = await setupServer();
  });

  test('Retrieve user list', () async {
    var channel = WebSocketChannel.connect(Uri.parse(
      'ws://$realtimeServerAddress:${server?.port ?? 4000}/users',
    ));

    final parsedResponse = channel.stream.cast<String>().map(json.decode);

    expect(
      parsedResponse,
      emitsInOrder([
        [
          {
            "users": {"id": 0, "name": "fred", "parent_id": 1},
            "parent": {
              "users": {"id": 1, "name": "omar", "parent_id": 0}
            }
          },
          {
            "users": {"id": 1, "name": "omar", "parent_id": 0},
            "parent": {
              "users": {"id": 0, "name": "fred", "parent_id": 1}
            }
          },
          {
            "users": {"id": 2, "name": "pataf", "parent_id": 0},
            "parent": {
              "users": {"id": 0, "name": "fred", "parent_id": 1}
            }
          },
          {
            "users": {"id": 3, "name": "skavinski", "parent_id": 0},
            "parent": {
              "users": {"id": 0, "name": "fred", "parent_id": 1}
            }
          }
        ],
      ]),
    );
  });

  test('Retrieve user list diffed and user added', () async {
    var channel = WebSocketChannel.connect(Uri.parse(
      'ws://$realtimeServerAddress:${server?.port ?? 4000}/users-diffed',
    ));
    final parsedResponse = channel.stream.cast<String>().map(json.decode);

    final newUserName = randomString();
    await get(Uri.parse(
      "http://$realtimeServerAddress:${server?.port ?? 4000}/addUser?name=$newUserName",
    ));

    expect(
      parsedResponse,
      emitsInOrder([
        [
          {
            "op": "replace",
            "path": "",
            "value": [
              {
                "users": {"id": 0, "name": "fred", "parent_id": 1},
                "parent": {
                  "users": {"id": 1, "name": "omar", "parent_id": 0}
                }
              },
              {
                "users": {"id": 1, "name": "omar", "parent_id": 0},
                "parent": {
                  "users": {"id": 0, "name": "fred", "parent_id": 1}
                }
              },
              {
                "users": {"id": 2, "name": "pataf", "parent_id": 0},
                "parent": {
                  "users": {"id": 0, "name": "fred", "parent_id": 1}
                }
              },
              {
                "users": {"id": 3, "name": "skavinski", "parent_id": 0},
                "parent": {
                  "users": {"id": 0, "name": "fred", "parent_id": 1}
                }
              }
            ]
          }
        ],
        [
          {
            'op': 'add',
            'path': '/-',
            'value': {
              'users': {'id': 4, 'name': newUserName, 'parent_id': 1},
              'parent': {
                'users': {'id': 1, 'name': 'omar', 'parent_id': 0}
              }
            }
          }
        ],
      ]),
    );
  });
}

Future<HttpServer> setupServer() async {
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

  // Setup db
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
      await PostgresTableSource(postgresClient, 'users', realtimeClient);
  final usersWithParent = await JoinOneToOne(
    usersDBSource,
    (e) => e['users']['parent_id'],
    usersDBSource,
    (e) => e['users']['id'],
    (e, v) => e['parent'] = v,
  );

  // Setup api server
  final app = Alfred();

  app.get(
    '/users',
    (req, res) => WebSocketSession(onOpen: (ws) {
      usersWithParent.stream.listen(
        (data) => ws.send(json.encode(data)),
      );
    }),
  );

  final usersDiffed = await Diffed(usersWithParent);
  app.get(
    '/users-diffed',
    (req, res) => WebSocketSession(onOpen: (ws) {
      usersDiffed.stream.listen(
        (data) => ws.send(json.encode(data)),
      );
    }),
  );

  app.get(
    '/addUser',
    (req, res) async {
      final name = req.uri.queryParameters['name'];
      await postgresClient.execute("""
        INSERT INTO "users" ("id", "name", "parent_id") VALUES
        (${usersWithParent.stream.value.length},	'${name ?? randomString()}', 1);
      """);
    },
  );

  // app.printRoutes();
  return await app.listen();
}
