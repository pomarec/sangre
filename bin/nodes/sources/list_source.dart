import '../node.dart';

class ListSource<Row> extends Node<List<Row>> {
  List<Row> _state = [];

  @override
  Future<void> init() async {
    streamController.add(_state);
  }

  insertRow(Row row) {
    _state.add(row);
    setRows(_state);
  }

  setRows(List<Row> rows) {
    _state = List.from(rows);
    streamController.add(_state);
  }

  updateRow(Row? Function(Row) map) {
    _state = List<Row>.from(_state)
        .map(map)
        .where((e) => e != null)
        .toList()
        .cast<Row>();
    streamController.add(_state);
  }
}
