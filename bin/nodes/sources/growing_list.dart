import '../node.dart';

class GrowingListSource extends Node<List> {
  final List _state = [];
  final int limit;

  GrowingListSource([this.limit = 5]) : super();

  @override
  onCreate() async {
    for (int i = 0; i < limit; i++) {
      // TODO : make sure when we plug two nodes, the first one emits its current state
      await Future.delayed(Duration(milliseconds: 100));
      _state.add(i);
      streamController.add(List.from(_state));
    }
    streamController.close();
  }
}
