import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:sangre/sangre.dart';

void main() async {
  final postgresClient = await setupDB();

  // Setup nodes
  final followedSource = await DB('users').get('id', 1).joinMany(
        'followeds',
        fromTable: DB('users').joinMany(
          'places',
          fromTable: PlacesOccupationFetcherNode(DB('places')),
        ),
      );

  // Setup api server
  final app = Alfred()
    ..sangre('/followeds', followedSource)
    ..get(
      '/unfollow',
      (req, res) async {
        final name = req.uri.queryParameters['name'];
        await postgresClient.execute("""
          INSERT INTO "users" ("id", "name") VALUES
          (${followedSource.stream.value.length},	'${name ?? randomString()}');
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
      (0,	'Fred'),
      (1,	'Omar'),
      (2,	'Jean'),
      (4,	'Roland');

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
      (1,	1),
      (2, 1);

      DROP TABLE IF EXISTS "places";
      CREATE TABLE "places" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL
      ) WITH (oids = false);
      ALTER TABLE "places" REPLICA IDENTITY FULL;
      INSERT INTO "places" ("id", "name") VALUES
      (0,	'Looloo Kitchen'),
      (1,	'La Cuisinerie'),
      (2,	'Cosinar Juntos'),
      (3,	'Pachamama'),
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
      (0, 5),
      (4, 5),
      (1, 5);
    """;
  await postgresClient.execute(sql);
  return postgresClient;
}

class PlacesOccupationFetcherNode extends NodeOperator1InputInterval<
    List<PostgresRowMap>, List<PostgresRowMap>> {
  PlacesOccupationFetcherNode(Node<List<PostgresRowMap>> nodeI1)
      : super(
          (places) async {
            // Here, places occupation is randomly set but we could
            // have retrieved this info from an external API since
            // we are in an async function

            final resp = List<PostgresRowMap>.from(places);
            for (var i = 0; i < min(3, resp.length); i++) {
              final randomIndex = Random().nextInt(resp.length);
              resp[randomIndex] = Map.from(resp[randomIndex])
                ..['occupation'] = Random().nextInt(5);
            }
            return resp;
          },
          nodeI1,
        );
}
