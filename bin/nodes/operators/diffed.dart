import 'package:json_patch/json_patch.dart';

import '../node.dart';

class Diffed<T> extends Node1Input<T, List<Map>> {
  T? _lastValue;

  Diffed(Node<T> nodeI1) : super(nodeI1);

  @override
  Future<List<Map>> process(T input) async {
    final diffs = JsonPatch.diff(_lastValue ?? "", input);
    _lastValue = input;
    return diffs;
  }
}
