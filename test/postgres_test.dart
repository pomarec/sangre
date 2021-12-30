// @Timeout(Duration(seconds: 10))

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../bin/nodes/sources/postgres_table.dart';

void main() async {
  var connection = PostgreSQLConnection(
    "localhost",
    5432,
    "tests",
    username: "postgres",
    password: "example",
  );
  await connection.open();

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
    await connection.execute(sql);
  });

  test('Postgres table retriving', () async {
    final source = await PostgresTableSource(connection, 'users');
    expect(
      source.stream,
      emitsInOrder([
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          }
        ],
      ]),
    );
  });

  test('Postgres table inserting', () async {
    final source = await PostgresTableSource(connection, 'users');

    await connection.execute("""
      INSERT INTO "users" ("id", "name") VALUES
      (2,	'patafouin');
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          },
        ],
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          },
          {
            'users': {'id': 2, 'name': 'patafouin'}
          }
        ],
      ]),
    );
  });

  test('Postgres table updating', () async {
    final source = await PostgresTableSource(connection, 'users');

    await connection.execute("""
      UPDATE "users"
      SET "name" = 'omarys'
      WHERE "id" = 1;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          },
        ],
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omarys'}
          },
        ],
      ]),
    );
  });

  test('Postgres table updating id', () async {
    final source = await PostgresTableSource(connection, 'users');

    await connection.execute("""
      UPDATE "users"
      SET "id" = 3, "name" = 'omarys'
      WHERE "id" = 1;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          },
        ],
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 3, 'name': 'omarys'}
          },
        ],
      ]),
    );
  });

  test('Postgres table deleting', () async {
    final source = await PostgresTableSource(connection, 'users');

    await connection.execute("""
      DELETE FROM "users"
      WHERE "id" = 0;
    """);
    expect(
      source.stream,
      emitsInOrder([
        [
          {
            'users': {'id': 0, 'name': 'fred'}
          },
          {
            'users': {'id': 1, 'name': 'omar'}
          },
        ],
        [
          {
            'users': {'id': 1, 'name': 'omar'}
          },
        ],
      ]),
    );
  });
}

//   => DB('users').to(Filter(group)).to(Join('places')).to(FetchPlaceDetail());

