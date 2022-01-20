import 'dart:async';
import 'dart:math';

import '../node.dart';
import '../sources/postgres_table.dart';

typedef _T = Map<String, dynamic>;

class JoinManyToMany<O extends _T>
    extends Node3Input<List<_T>, List<_T>, List<_T>, List<O>> with Joinable<O> {
  final String joinKey;
  final String jtJoinKey;
  final String jtValueKey;

  JoinManyToMany(
    Node<List<_T>> nodeI1,
    this.joinKey,
    Node<List<_T>> nodeI2,
    this.jtJoinKey,
    this.jtValueKey,
    Node<List<_T>> nodeI3,
  ) : super(nodeI1, nodeI2, nodeI3);

  String get tableName => (nodeI1 as PostgresTableSource).tableName;

  @override
  Future<List<O>> process(
    List<_T> input1,
    List<_T> input2,
    List<_T> input3,
  ) async =>
      // We need to copy items, otherwise operators may modify parents operators items
      // TODO: real deep copy, this is a shallow copy
      List.of(input1).map((e) {
        final input1Element = Map<String, dynamic>.from(e) as O;
        final joinedIds = input2
            .where((e) => e[jtJoinKey] == input1Element['id'])
            .map((e) => e[jtValueKey])
            .toList();
        final joinedItems = joinedIds
            .map((joinId) => Map.from(input3.firstWhere(
                  (e) => e['id'] == joinId,
                )))
            .toList();
        input1Element[joinKey] = joinedItems;
        return input1Element;
      }).toList();
}

mixin Joinable<T extends PostgresRowMap> on Node<List<T>> {
  String get tableName;

  Future<Joinable<T>> joinMany(
    String joinKey, {
    String? fromTableName,
    Node<List<PostgresRowMap>>? fromTable,
  }) async =>
      await JoinManyToMany(
        await this,
        joinKey,
        await PostgresTableSource("${tableName}_$joinKey"),
        _tableNameToId(tableName),
        _tableNameToId(joinKey),
        fromTable != null
            ? await fromTable
            : fromTableName != null
                ? await PostgresTableSource(fromTableName)
                : await this,
      ) as Joinable<T>;

  static String _tableNameToId(String tableName) =>
      "${tableName.substring(0, max(tableName.length - 1, 0))}_id";
}

extension JoinableFuture<T extends PostgresRowMap> on Future<Joinable<T>> {
  Future<Joinable<T>> joinMany(
    String joinKey, {
    String? fromTableName,
    Node<List<PostgresRowMap>>? fromTable,
  }) async =>
      await (await this).joinMany(
        joinKey,
        fromTableName: fromTableName,
        fromTable: fromTable,
      );
}
