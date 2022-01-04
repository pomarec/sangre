import '../node.dart';

class Logger<T> extends Node1Input<T, T> {
  Logger(Node<T> nodeI1) : super(nodeI1);

  @override
  Future<T> process(T input) async {
    print(input);
    return input;
  }
}
