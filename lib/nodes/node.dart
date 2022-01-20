import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../async_init.dart';
import '../utils.dart';

export '../async_init.dart';

/// Any node, especially sources, have to seed their stream with
/// at least one value before the end of init().
abstract class Node<Output> with AsyncInitMixin<Node<Output>> {
  /// This should be set at initialization once and never touched then
  String nodeId = "Uninitialized";

  final BehaviorSubject<Output> streamController = BehaviorSubject();
  ValueStream<Output> get stream => streamController.stream;

  @override
  Future<void> init() async {
    await super.init();
    nodeId = typeName;
  }

  Future close() => streamController.close();
}

abstract class Node1Input<I1, Output> extends Node<Output> {
  final Node<I1> nodeI1;

  Node1Input(this.nodeI1);

  @override
  Future<void> init() async {
    nodeId = "$typeName[${this.nodeI1.nodeId}]";
    (await nodeI1).stream.asyncMap(process).listen(streamController.add);
  }

  Future<Output> process(I1 input) async => throw UnimplementedError();
}

abstract class Node2Input<I1, I2, Output> extends Node<Output> {
  final Node<I1> nodeI1;
  final Node<I2> nodeI2;

  Node2Input(this.nodeI1, this.nodeI2);

  @override
  Future<void> init() async {
    nodeId = "$typeName[${this.nodeI1.nodeId}, ${this.nodeI2.nodeId}]";
    Rx.combineLatest2(
      (await nodeI1).stream,
      (await nodeI2).stream,
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
    nodeId =
        "$typeName[${this.nodeI1.nodeId}, ${this.nodeI2.nodeId}, ${this.nodeI3.nodeId}]";
    Rx.combineLatest3(
      (await nodeI1).stream,
      (await nodeI2).stream,
      (await nodeI3).stream,
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