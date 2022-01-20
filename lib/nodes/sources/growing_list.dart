import 'list_source.dart';

class GrowingListSource extends ListSource<int> {
  final int limit;

  GrowingListSource([this.limit = 5]) : super();

  @override
  Future<void> init() async {
    await super.init();

    insertRow(0);

    for (int i = 1; i < limit; i++)
      Future.delayed(
        Duration(milliseconds: (i + 1) * 100),
        () => insertRow(i),
      );

    Future.delayed(
      Duration(milliseconds: (limit + 1) * 100),
      close,
    );
  }
}
