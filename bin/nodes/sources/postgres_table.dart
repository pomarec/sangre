import 'dart:async';

import 'package:postgres/postgres.dart';

import 'list_source.dart';

typedef PostgresRowMap = Map<String, Map<String, dynamic>>;

class PostgresTableSource extends ListSource<PostgresRowMap> {
  final PostgreSQLConnection connection;
  final String tableName;

  StreamController<List<PostgresRowMap>>? _queryStreamController;

  PostgresTableSource(this.connection, this.tableName);

  @override
  Future<void> init() async {
    await super.init();
    setRows(await _fetchResults());

    _queryStreamController = StreamController();
    _queryStreamController?.addStream(
      Stream.periodic(Duration(seconds: 1)).asyncMap(
        (_) => _fetchResults(),
      ),
    );
    _queryStreamController?.stream.listen(setRows);
  }

  Future<List<PostgresRowMap>> _fetchResults() async =>
      connection.mappedResultsQuery(
        "SELECT * FROM $tableName",
      );

  @override
  Future close() async {
    await super.close();
    await _queryStreamController?.close();
  }
}
