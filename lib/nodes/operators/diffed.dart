import 'dart:convert';

import 'package:json_patch/json_patch.dart';
import 'package:postgres/postgres.dart';

import '../node.dart';

typedef DiffedDataWithRevision = Map<String, dynamic>;

class Diffed<T> extends Node1Input<T, DiffedDataWithRevision> {
  final PostgreSQLConnection postgresClient;
  T? lastValue;
  int revision = 0;
  final String tableName;

  Diffed(
    Node<T> nodeI1,
    this.postgresClient, {
    this.tableName = "sangre_nodes_diff_history",
  }) : super(nodeI1);

  @override
  Future<void> init() async {
    await _createHistoryTable();
    await super.init();
  }

  @override
  Future<DiffedDataWithRevision> process(T input) async {
    final diffs = JsonPatch.diff(lastValue ?? "", input);
    if (diffs.length == 0) throw NodeSkipProcess();
    lastValue = JsonPatch.apply(lastValue ?? "", diffs);
    revision++;
    await _saveCurrentRevision();
    return {
      "revision": revision,
      "diffs": diffs,
    };
  }

  Future<DiffedDataWithRevision> diffsFromRevision(
    int? previousRevision,
  ) async {
    dynamic previousRevisionValue = "";

    if (previousRevision != null && previousRevision > 0) {
      final previousRevisionResults = await postgresClient.mappedResultsQuery(
        """
          SELECT ("snapshot") FROM "$tableName" 
          WHERE id='$nodeId' AND revision='$previousRevision';
        """,
      );
      final snapshot = previousRevisionResults[0][tableName]?["snapshot"];
      if (snapshot != null) previousRevisionValue = snapshot;
    }
    final diffs = JsonPatch.diff(previousRevisionValue, lastValue);
    return {
      "revision": revision,
      "diffs": diffs,
    };
  }

  _createHistoryTable() async => postgresClient.execute("""
    DROP TABLE IF EXISTS "$tableName";

    CREATE TABLE "$tableName" (
      "id" VARCHAR(255) NOT NULL,
      "revision" integer NOT NULL,
      "snapshot" jsonb
    );

    ALTER TABLE "$tableName" REPLICA IDENTITY FULL;
  """);

  _saveCurrentRevision() async => postgresClient.execute("""
    INSERT INTO "$tableName" ("id", "revision", "snapshot") VALUES
    ('$nodeId',	$revision, '${json.encode(lastValue)}');
  """);
}
