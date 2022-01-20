import 'dart:async';

import '../node.dart';

/// A node operator is a node which process() is based on a operator
/// An operator is a pure function.

class NodeOperator1Input<I1, Output> extends Node1Input<I1, Output> {
  final Future<Output> Function(I1) op;

  NodeOperator1Input(
    this.op,
    Node<I1> nodeI1,
  ) : super(nodeI1);

  @override
  Future<Output> process(I1 input) async => await op(input);
}

class NodeOperator2Input<I1, I2, Output> extends Node2Input<I1, I2, Output> {
  final Future<Output> Function(I1, I2) op;

  NodeOperator2Input(
    this.op,
    Node<I1> nodeI1,
    Node<I2> nodeI2,
  ) : super(nodeI1, nodeI2);

  @override
  Future<Output> process(I1 input1, I2 input2) async =>
      await op(input1, input2);
}

class NodeOperator3Input<I1, I2, I3, Output>
    extends Node3Input<I1, I2, I3, Output> {
  final Future<Output> Function(I1, I2, I3) op;

  NodeOperator3Input(
    this.op,
    Node<I1> nodeI1,
    Node<I2> nodeI2,
    Node<I3> nodeI3,
  ) : super(nodeI1, nodeI2, nodeI3);

  @override
  Future<Output> process(I1 input1, I2 input2, I3 input3) async =>
      await op(input1, input2, input3);
}

class NodeOperator1InputInterval<I1, Output>
    extends NodeOperator1Input<I1, Output> {
  Timer? timer;
  final Duration interval;

  NodeOperator1InputInterval(Future<Output> Function(I1 p1) op, Node<I1> nodeI1,
      [Duration? interval])
      : interval = Duration(seconds: 5),
        super(op, nodeI1);

  @override
  Future<void> init() async {
    await super.init();
    timer = Timer.periodic(
      interval,
      (_) async => streamController.add(
        await process(nodeI1.stream.value),
      ),
    );
  }

  @override
  Future close() async {
    timer?.cancel();
    await super.close();
  }
}
