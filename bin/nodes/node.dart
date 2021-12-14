import 'dart:async';

import 'package:rxdart/rxdart.dart';

abstract class Node<Output> {
  final StreamController<Output> streamController =
      StreamController.broadcast();
  Stream<Output> get stream => streamController.stream;

  Node() {
    onCreate();
  }

  onCreate() async {}
}

abstract class Node1Input<I1, Output> extends Node<Output> {
  final Node<I1> nodeI1;

  Node1Input(this.nodeI1) {
    nodeI1.stream.map(process).pipe(streamController);
  }

  Output process(I1 input) => throw UnimplementedError();
}

abstract class Node2Input<I1, I2, Output> extends Node<Output> {
  final Node<I1> nodeI1;
  final Node<I2> nodeI2;

  Node2Input(this.nodeI1, this.nodeI2) {
    Rx.combineLatest2(
      nodeI1.stream,
      nodeI2.stream,
      process,
    ).pipe(streamController);
  }

  Output process(I1 input1, I2 input2) => throw UnimplementedError();
}
