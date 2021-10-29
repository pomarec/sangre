import 'dart:async';

abstract class Source<T> {
  final StreamController<T> egressController = StreamController();
  Stream<T> get egress => egressController.stream;

  Source() {
    onCreate();
  }

  onCreate() async {
    throw UnimplementedError();
  }
}
