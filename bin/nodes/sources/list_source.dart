import '../node.dart';

class ListSource<Row> extends Node<List<Row>> {
  final List<Row> _state = [];

  @override
  Future<void> init() async {
    streamController.add(_state);
  }

  insertRow(Row row) {
    _state.add(row);
    setRows(_state);
  }

  setRows(List<Row> rows) => streamController.add(
        List.from(rows),
      );
}
