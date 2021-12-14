import 'node.dart';

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
