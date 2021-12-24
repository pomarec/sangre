import '../node.dart';

class GrowingListSource extends Node<List<int>> {
  final List _state = [];
  final int limit;

  GrowingListSource([this.limit = 5]) : super();

  @override
  Future<void> init() async {
    for (int i = 0; i < limit; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      _state.add(i);
      streamController.add(List.from(_state));
    }
    streamController.close();
  }
}
