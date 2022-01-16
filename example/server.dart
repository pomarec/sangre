import 'package:alfred/alfred.dart';
import 'package:sangre/sangre.dart';

typedef DB = PostgresTableSource;

void main() async {
  final postgresClient = await setupDB();

  // Setup nodes
  final usersDBSource = await DB('users').joinMany('followeds');

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
      (2,	'Solemior');

      DROP TABLE IF EXISTS "users_places";
      CREATE TABLE "users_places" (
        "user_id" integer NOT NULL,
        "place_id" integer NOT NULL
      );
      ALTER TABLE "users_places" REPLICA IDENTITY FULL;
      INSERT INTO "users_places" ("user_id", "place_id") VALUES
      (0,	1),
      (1,	2),
      (1,	0),
      (2, 1),
      (0, 2);
    """;
  await postgresClient.execute(sql);
  return postgresClient;
}
