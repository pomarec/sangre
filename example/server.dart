import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:sangre/sangre.dart';

void main() async {
  var postgresClient = PostgreSQLConnection(
    "localhost",
    5432,
    "tests",
    username: "postgres",
    password: "example",
  );
  final realtimeClient = RealtimeClient('ws://localhost:4000/socket');
  await postgresClient.open();
  realtimeClient.connect();

  // Setup db
  final sql = """
      DROP TABLE IF EXISTS "users";
      CREATE TABLE "public"."users" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL
      ) WITH (oids = false);

      ALTER TABLE "users" REPLICA IDENTITY FULL;

      INSERT INTO "users" ("id", "name") VALUES
      (0,	'fred'),
      (1,	'omar'),
      (2,	'pataf');
    """;
  await postgresClient.execute(sql);

  // Setup nodes
  final usersDBSource =
      await PostgresTableSource(postgresClient, 'users', realtimeClient);

  // Setup api server
  final app = Alfred();

  app.get(
    '/users',
    (req, res) => WebSocketSession(onOpen: (ws) {
      usersDBSource.stream.listen(
        (data) => ws.send(json.encode(data)),
      );
    }),
  );

  final usersDiffed = await Diffed(usersDBSource);
  app.get(
    '/users-diffed',
    (req, res) => WebSocketSession(onOpen: (ws) {
      ws.send(json.encode(usersDiffed.lastValue));
      usersDiffed.stream.skip(1).listen(
            (data) => ws.send(json.encode(data)),
          );
    }),
  );

  app.get(
    '/addUser',
    (req, res) async {
      final name = req.uri.queryParameters['name'];
      await postgresClient.execute("""
        INSERT INTO "users" ("id", "name") VALUES
        (${usersDBSource.stream.value.length},	'${name ?? "nobody"}');
      """);
    },
  );

  // app.printRoutes();
  await app.listen();
}
