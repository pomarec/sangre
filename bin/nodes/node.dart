import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../lib/async_init.dart';

abstract class Node<Output> with AsyncInitMixin<Node<Output>> {
  final BehaviorSubject<Output> streamController = BehaviorSubject();
  ValueStream<Output> get stream => streamController.stream;

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

  Node2Input(this.nodeI1, this.nodeI2);

  @override
  Future<void> init() async {
    Rx.combineLatest2(
      nodeI1.stream,
      nodeI2.stream,
      (I1 a, I2 b) => Tuple2(a, b),
    )
        .asyncMap(
          (tuple) async => await process(tuple.value1, tuple.value2),
        )
        .pipe(streamController);
    await streamController.first;
  }

  Future<Output> process(I1 input1, I2 input2) async =>
      throw UnimplementedError();
}

abstract class Node3Input<I1, I2, I3, Output> extends Node<Output> {
  final Node<I1> nodeI1;
  final Node<I2> nodeI2;
  final Node<I3> nodeI3;

  Node3Input(this.nodeI1, this.nodeI2, this.nodeI3);

  @override
  Future<void> init() async {
    Rx.combineLatest3(
      nodeI1.stream,
      nodeI2.stream,
      nodeI3.stream,
      (I1 a, I2 b, I3 c) => Tuple3(a, b, c),
    )
        .asyncMap(
          (tuple) async =>
              await process(tuple.value1, tuple.value2, tuple.value3),
        )
        .pipe(streamController);
    await streamController.first;
  }

  Future<Output> process(I1 input1, I2 input2, I3 input3) async =>
      throw UnimplementedError();
}
