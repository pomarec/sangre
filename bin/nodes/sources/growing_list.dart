import '../node.dart';

class GrowingListSource extends Node<List<int>> {
  final List _state = [];
  final int limit;

  GrowingListSource([this.limit = 5]) : super();

  @override
  Future<void> init() async {
    for (int i = 0; i < limit; i++)
      Future.delayed(
        Duration(milliseconds: (i + 1) * 100),
        () {
          _state.add(i);
          streamController.add(List.from(_state));
        },
      );

    Future.delayed(
      Duration(milliseconds: (limit + 1) * 100),
      streamController.close,
    );
  }
}
