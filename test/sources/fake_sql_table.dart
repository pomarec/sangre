import '../../bin/nodes/node.dart';

class FakeSQLTableSource<Row> extends Node<List<Row>> {
  final List<Row> _state = [];

  FakeSQLTableSource() : super();

  insertRow(Row row) {
    _state.add(row);
    streamController.add(
      List.from(_state),
    );
  }
}
