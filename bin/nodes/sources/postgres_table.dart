import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:realtime_client/realtime_client.dart';

import 'list_source.dart';

typedef PostgresRowMap = Map<String, Map<String, dynamic>>;

class PostgresTableSource extends ListSource<PostgresRowMap> {
  final PostgreSQLConnection connection;
  final String tableName;

  StreamController<List<PostgresRowMap>>? _queryStreamController;
  RealtimeClient? _realtimeSocket;

  PostgresTableSource(this.connection, this.tableName);

  @override
  Future<void> init() async {
    await super.init();
    setRows(await _fetchResults());

    // await setupPolling();
    await setupRealtime();
  }

  Future<List<PostgresRowMap>> _fetchResults() async =>
      connection.mappedResultsQuery(
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
    final realtimeSocket = RealtimeClient(
      'ws://localhost:4000/socket',
      logger: (kind, msg, data) => print('$kind $msg $data'),
    );

    _realtimeSocket = _realtimeSocket;

    final channel = realtimeSocket.channel('realtime:public:$tableName');
    channel.on(
      'INSERT',
      (payload, {ref}) => insertRow({
        tableName: convertChangeData(
          (payload['columns'] as List).cast<Map<String, dynamic>>(),
          payload['record'],
        ),
      }),
    );
    channel.on('UPDATE', (payload, {ref}) {
      final typedRow = {
        tableName: convertChangeData(
          (payload['columns'] as List).cast<Map<String, dynamic>>(),
          payload['record'],
        )
      };
      updateRows(
        (row) => row[tableName]!['id'] == typedRow[tableName]!['id']
            ? typedRow
            : row,
      );
    });

    realtimeSocket.connect();
    channel.subscribe();

    // Wait for channel to be joined
    int maxRetries = 5;
    while (!channel.isJoined() && maxRetries-- > 0)
      await Future.delayed(Duration(milliseconds: 200));
  }

  @override
  Future close() async {
    await super.close();
    await _queryStreamController?.close();
    _realtimeSocket?.disconnect();
  }
}
