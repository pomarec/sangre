import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:sangre/sangre.dart';

typedef DB = PostgresTableSource;

void main() async {
  final postgresClient = await setupDB();

  // Setup nodes
  final a = DB('users')
      .joinMany('places', fromTable: PlacesRaterNode(DB('places')))
      .joinMany('followeds');

  final usersDBSource = await a;

  // Setup api server
  final app = Alfred()
    ..sangre('/users', usersDBSource)
    ..get(
      '/addUser',
      (req, res) async {
        final name = req.uri.queryParameters['name'];
        await postgresClient.execute("""
          INSERT INTO "users" ("id", "name") VALUES
          (${usersDBSource.stream.value.length},	'${name ?? randomString()}');
        """);
      },
    );

  await app.listen();
}

Future<PostgreSQLConnection> setupDB() async {
  var postgresClient = PostgreSQLConnection(
    "localhost",
    5432,
    "tests",
    username: "postgres",
    password: "example",
  );
  PostgresTableSource.globalPostgresClient = postgresClient;
  final realtimeClient = RealtimeClient('ws://localhost:4000/socket');
  PostgresTableSource.globalRealtimeClient = realtimeClient;
  await postgresClient.open();
  realtimeClient.connect();

  // Setup db
  final sql = """
      DROP TABLE IF EXISTS "users";
      CREATE TABLE "users" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL
      ) WITH (oids = false);
      ALTER TABLE "users" REPLICA IDENTITY FULL;
      INSERT INTO "users" ("id", "name") VALUES
      (0,	'fred'),
      (1,	'omar'),
      (2,	'pataf');

      DROP TABLE IF EXISTS "users_followeds";
      CREATE TABLE "users_followeds" (
        "user_id" integer NOT NULL,
        "followed_id" integer NOT NULL
      );
      ALTER TABLE "users_followeds" REPLICA IDENTITY FULL;
      INSERT INTO "users_followeds" ("user_id", "followed_id") VALUES
      (0,	1),
      (1,	2),
      (1,	0),
      (2, 1);


      DROP TABLE IF EXISTS "places";
      CREATE TABLE "places" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL
      ) WITH (oids = false);
      ALTER TABLE "places" REPLICA IDENTITY FULL;
      INSERT INTO "places" ("id", "name") VALUES
      (0,	'Rakwe'),
      (1,	'La Cuisinerie'),
      (2,	'Solemior'),
      (3,	'Les douceurs de lorient'),
      (4,	'Philoo'),
      (5,	'Duropam');

      DROP TABLE IF EXISTS "users_places";
      CREATE TABLE "users_places" (
        "user_id" integer NOT NULL,
        "place_id" integer NOT NULL
      );
      ALTER TABLE "users_places" REPLICA IDENTITY FULL;
      INSERT INTO "users_places" ("user_id", "place_id") VALUES
      (0,	1),
      (1,	2),
      (1,	3),
      (2, 4),
      (0, 5);
    """;
  await postgresClient.execute(sql);
  return postgresClient;
}

class PlacesRaterNode extends NodeOperator1InputInterval<List<PostgresRowMap>,
    List<PostgresRowMap>> {
  PlacesRaterNode(Node<List<PostgresRowMap>> nodeI1)
      : super(
          (places) async {
            final resp = List<PostgresRowMap>.from(places);
            final randomIndex = Random().nextInt(resp.length);
            resp[randomIndex] = Map.from(resp[randomIndex])
              ..['rating'] = Random().nextInt(5);
            return resp;
          },
          nodeI1,
        );
}
