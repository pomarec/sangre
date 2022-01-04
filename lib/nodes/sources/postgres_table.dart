import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:realtime_client/realtime_client.dart';

import 'list_source.dart';

typedef PostgresRowMap = Map<String, Map<String, dynamic>>;

class PostgresTableSource extends ListSource<PostgresRowMap> {
  final PostgreSQLConnection postgresClient;
  final RealtimeClient? realtimeClient;
  final String tableName;

  StreamController<List<PostgresRowMap>>? _queryStreamController;
  RealtimeSubscription? _realtimeChannel;

  PostgresTableSource(
    this.postgresClient,
    this.tableName, [
    this.realtimeClient,
  ]);

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
      postgresClient.mappedResultsQuery(
        "SELECT * FROM $tableName",
      );

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
        (payload, {ref}) => insertRow({
          tableName: convertChangeData(
            (payload['columns'] as List).cast<Map<String, dynamic>>(),
            payload['record'],
          ),
        }),
      );
      channel.on(
        'UPDATE',
        (payload, {ref}) {
          final typedOldRow = {
            tableName: convertChangeData(
              (payload['columns'] as List).cast<Map<String, dynamic>>(),
              payload['old_record'],
            )
          };
          final typedNewRow = {
            tableName: convertChangeData(
              (payload['columns'] as List).cast<Map<String, dynamic>>(),
              payload['record'],
            )
          };
          updateRows(
            (row) => row[tableName]!['id'] == typedOldRow[tableName]!['id']
                ? typedNewRow
                : row,
          );
        },
      );
      channel.on(
        'DELETE',
        (payload, {ref}) {
          final typedRow = {
            tableName: convertChangeData(
              (payload['columns'] as List).cast<Map<String, dynamic>>(),
              payload['old_record'],
            )
          };
          updateRows(
            (row) => row[tableName]!['id'] == typedRow[tableName]!['id']
                ? null
                : row,
          );
        },
      );
      channel.subscribe();

      // Wait for channel to be joined
      int maxRetries = 5;
      while (!channel.isJoined() && maxRetries-- > 0)
        await Future.delayed(Duration(milliseconds: 200));
    }
  }

  @override
  Future close() async {
    await super.close();
    await _queryStreamController?.close();
    _realtimeChannel?.unsubscribe();
  }
}
