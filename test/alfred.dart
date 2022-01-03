import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:postgres/postgres.dart';
import 'package:realtime_client/realtime_client.dart';

import '../bin/nodes/operators/diffed.dart';
import '../bin/nodes/operators/join_one_to_one.dart';
import '../bin/nodes/sources/postgres_table.dart';

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
    (req, res) => postgresClient.execute("""
      INSERT INTO "users" ("id", "name", "parent_id") VALUES
      (${usersWithParent.stream.value.length},	'popof', 1);
    """),
  );

  app.printRoutes();
  await app.listen();
}
