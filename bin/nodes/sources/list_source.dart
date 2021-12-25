import '../node.dart';

class ListSource<Row> extends Node<List<Row>> {
  final List<Row> _state = [];

  @override
  Future<void> init() async {
    streamController.add([]);
  }

  insertRow(Row row) {
    _state.add(row);
    streamController.add(
      List.from(_state),
    );
  }
}
