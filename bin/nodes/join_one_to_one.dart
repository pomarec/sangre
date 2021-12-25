import 'node.dart';

class JoinOneToOne extends Node2Input<List<Map<String, dynamic>>,
    List<Map<String, dynamic>>, List<Map<String, dynamic>>> {
  final dynamic joinKey;
  final dynamic matchingKey;

  JoinOneToOne(
    Node<List<Map<String, dynamic>>> nodeI1,
    this.joinKey,
    Node<List<Map<String, dynamic>>> nodeI2, [
    this.matchingKey = 'id',
  ]) : super(nodeI1, nodeI2);

  @override
  Future<List<Map<String, dynamic>>> process(
    List<Map<String, dynamic>> input1,
    List<Map<String, dynamic>> input2,
  ) async =>
      List.generate(
        input1.length,
        (index) => Map<String, dynamic>.from(input1[index])
          ..[joinKey] = input2.firstWhere(
            (input2Element) =>
                input2Element[matchingKey] == input1[index][joinKey],
            orElse: () => {},
          ),
      );
}
