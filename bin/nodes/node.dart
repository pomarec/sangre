import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

abstract class Node<Output> {
  final BehaviorSubject<Output> streamController = BehaviorSubject();
  Stream<Output> get stream => streamController.stream;

  Node() {
    onCreate();
  }

  onCreate() async {}

  close() => streamController.close();
}

abstract class Node1Input<I1, Output> extends Node<Output> {
  final Node<I1> nodeI1;

  Node1Input(this.nodeI1) {
    nodeI1.stream.asyncMap(process).pipe(streamController);
  }

  Future<Output> process(I1 input) async => throw UnimplementedError();
}

abstract class Node2Input<I1, I2, Output> extends Node<Output> {
  final Node<I1> nodeI1;
  final Node<I2> nodeI2;

  Node2Input(this.nodeI1, this.nodeI2) {
    Rx.combineLatest2(
      nodeI1.stream,
      nodeI2.stream,
      (I1 a, I2 b) => Tuple2(a, b),
    )
        .asyncMap(
          (tuple) async => await process(tuple.value1, tuple.value2),
        )
        .pipe(streamController);
  }

  Future<Output> process(I1 input1, I2 input2) async =>
      throw UnimplementedError();
}
