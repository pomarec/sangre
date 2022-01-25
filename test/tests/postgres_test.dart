// @Timeout(Duration(seconds: 10))

import 'package:sangre/sangre.dart';
import 'package:test/test.dart';

import '../env.dart';

void main() async {
  var postgresClient = PostgreSQLConnection(
    postgresServerAddress,
    5432,
    "postgres",
    username: "postgres",
    password: "example",
  );
  final realtimeClient = RealtimeClient(
    'ws://$realtimeServerAddress:4000/socket',
    // logger: (kind, msg, data) => print('$kind $msg $data'),
  );
  await postgresClient.open();
  realtimeClient.connect();

  // Prepare a clear test db
  setUp(() async {
    final sql = """
      DROP TABLE IF EXISTS "users";
      CREATE TABLE "public"."users" (
          "id" integer NOT NULL,
          "name" character varying NOT NULL
      ) WITH (oids = false);

      ALTER TABLE "users" REPLICA IDENTITY FULL;

      INSERT INTO "users" ("id", "name") VALUES
      (0,	'fred'),
      (1,	'omar');
    """;
    await postgresClient.execute(sql);
  });

  test('Postgres table retriving', () async {
    final source =
        await PostgresTableSource('users', postgresClient, realtimeClient);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
      ]),
    );
  });

  test('Postgres table inserting', () async {
    final source =
        await PostgresTableSource('users', postgresClient, realtimeClient);

    await postgresClient.execute("""
      INSERT INTO "users" ("id", "name") VALUES
      (2,	'patafouin');
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'},
          {'id': 2, 'name': 'patafouin'}
        ],
      ]),
    );
  });

  test('Postgres table inserting (Polling)', () async {
    final source = await PostgresTableSource('users', postgresClient);

    await postgresClient.execute("""
      INSERT INTO "users" ("id", "name") VALUES
      (2,	'patafouin');
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'},
          {'id': 2, 'name': 'patafouin'},
        ],
      ]),
    );
  });

  test('Postgres table updating', () async {
    final source =
        await PostgresTableSource('users', postgresClient, realtimeClient);

    await postgresClient.execute("""
      UPDATE "users"
      SET "name" = 'omarys'
      WHERE "id" = 1;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omarys'},
        ],
      ]),
    );
  });

  test('Postgres table updating id', () async {
    final source =
        await PostgresTableSource('users', postgresClient, realtimeClient);

    await postgresClient.execute("""
      UPDATE "users"
      SET "id" = 3, "name" = 'omarys'
      WHERE "id" = 1;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
        [
          {'id': 0, 'name': 'fred'},
          {'id': 3, 'name': 'omarys'},
        ],
      ]),
    );
  });

  test('Postgres table deleting', () async {
    final source =
        await PostgresTableSource('users', postgresClient, realtimeClient);

    await postgresClient.execute("""
      DELETE FROM "users"
      WHERE "id" = 0;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {'id': 0, 'name': 'fred'},
          {'id': 1, 'name': 'omar'}
        ],
        [
          {'id': 1, 'name': 'omar'},
        ],
      ]),
    );
  });

  test('Postgres table with relationship & operators', () async {
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
        await PostgresTableSource('users', postgresClient, realtimeClient);
    final usersWithParent = await JoinOneToOne(
      usersDBSource,
      (e) => e['parent_id'],
      usersDBSource,
      (e) => e['id'],
      (e, v) => e['parent'] = v,
    );
    final usersWithChildrenCount = await NodeOperator1Input(
      (a) async => a, // a['parent_count'] = a['parents'].length,
      usersWithParent,
    );

    // Test
    expect(
      usersWithChildrenCount.stream,
      emitsInOrder([
        [
          {
            'id': 0,
            'name': "fred",
            'parent_id': 1,
            'parent': {'id': 1, 'name': "omar", 'parent_id': 0}
          },
          {
            'id': 1,
            'name': "omar",
            'parent_id': 0,
            'parent': {'id': 0, 'name': "fred", 'parent_id': 1},
          },
          {
            'id': 2,
            'name': "pataf",
            'parent_id': 0,
            'parent': {'id': 0, 'name': "fred", 'parent_id': 1},
          },
          {
            'id': 3,
            'name': "skavinski",
            'parent_id': 0,
            'parent': {'id': 0, 'name': "fred", 'parent_id': 1}
          }
        ]
      ]),
    );
  });
}
