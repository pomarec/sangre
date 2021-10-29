import 'source.dart';

class GrowingListSouce extends Source<List> {
  final List _state = [];
  final int limit;

  GrowingListSouce([this.limit = 5]) : super();

  @override
  onCreate() async {
    for (int i = 0; i < limit; i++) {
      _state.add(i);
      egressController.add(List.from(_state));
      await Future.delayed(Duration(milliseconds: 100));
    }
    egressController.close();
  }
}
