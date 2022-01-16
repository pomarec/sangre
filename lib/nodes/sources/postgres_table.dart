import 'dart:async';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:sangre/nodes/operators/join_many_to_many.dart';

import 'list_source.dart';

typedef PostgresRowMap = Map<String, dynamic>;

class PostgresTableSource extends ListSource<PostgresRowMap> {
  static PostgreSQLConnection? globalPostgresClient;
  static RealtimeClient? globalRealtimeClient;

  final PostgreSQLConnection postgresClient;
  final RealtimeClient? realtimeClient;
  final String tableName;

  StreamController<List<PostgresRowMap>>? _queryStreamController;
  RealtimeSubscription? _realtimeChannel;

  PostgresTableSource(
    this.tableName, [
    PostgreSQLConnection? postgresClient,
    RealtimeClient? realtimeClient,
  ])  : postgresClient = globalPostgresClient ?? postgresClient!,
        realtimeClient = globalRealtimeClient ?? realtimeClient;

  @override
  Future<void> init() async {
    await super.init();
    setRows(await _fetchResults());

    if (realtimeClient != null)
      await setupRealtime();
    else
      await setupPolling();
  }

  Future<List<PostgresRowMap>> _fetchResults() async =>
      (await postgresClient.mappedResultsQuery(
        "SELECT * FROM $tableName",
      ))
          .map((e) => e[tableName])
          .cast<PostgresRowMap>()
          .toList();

  setupPolling() async {
    _queryStreamController = StreamController();
    _queryStreamController?.addStream(
      Stream.periodic(Duration(seconds: 1)).asyncMap(
        (_) => _fetchResults(),
      ),
    );
    _queryStreamController?.stream.listen(setRows);
  }

  setupRealtime() async {
    if (realtimeClient != null) {
      final channel = realtimeClient!.channel('realtime:public:$tableName');
      _realtimeChannel = channel;
      channel.on(
        'INSERT',
        (payload, {ref}) => insertRow(
          convertChangeData(
            (payload['columns'] as List).cast<Map<String, dynamic>>(),
            payload['record'],
          ),
        ),
      );
      channel.on(
        'UPDATE',
        (payload, {ref}) {
          final typedOldRow = convertChangeData(
            (payload['columns'] as List).cast<Map<String, dynamic>>(),
            payload['old_record'],
          );
          final typedNewRow = convertChangeData(
            (payload['columns'] as List).cast<Map<String, dynamic>>(),
            payload['record'],
          );
          updateRows(
            (row) => row['id'] == typedOldRow['id'] ? typedNewRow : row,
          );
        },
      );
      channel.on(
        'DELETE',
        (payload, {ref}) {
          final typedRow = convertChangeData(
            (payload['columns'] as List).cast<Map<String, dynamic>>(),
            payload['old_record'],
          );
          updateRows(
            (row) => row['id'] == typedRow['id'] ? null : row,
          );
        },
      );
      channel.subscribe();

      // Wait for channel to be joined
      int maxRetries = 5;
      while (!channel.isJoined() && maxRetries-- > 0)
        await Future.delayed(Duration(milliseconds: 50));
    }
  }

  @override
  Future close() async {
    await super.close();
    await _queryStreamController?.close();
    _realtimeChannel?.unsubscribe();
  }

  Future<JoinManyToMany> joinMany(
    String joinKey, [
    String? joinedTableName,
  ]) async =>
      await JoinManyToMany(
        await this,
        joinKey,
        await PostgresTableSource("${tableName}_$joinKey"),
        _tableNameToId(tableName),
        _tableNameToId(joinKey),
        joinedTableName != null
            ? PostgresTableSource(joinedTableName)
            : await this,
      );

  static String _tableNameToId(String tableName) =>
      "${tableName.substring(0, max(tableName.length - 1, 0))}_id";
}
