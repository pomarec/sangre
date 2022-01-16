import '../node.dart';

typedef _T = Map<String, dynamic>;

class JoinManyToMany<O extends _T>
    extends Node3Input<List<_T>, List<_T>, List<_T>, List<O>> {
  final String joinKey;
  final String jtJoinKey;
  final String jtValueKey;

  JoinManyToMany(
    Node<List<_T>> nodeI1,
    this.joinKey,
    Node<List<_T>> nodeI2,
    this.jtJoinKey,
    this.jtValueKey,
    Node<List<_T>> nodeI3,
  ) : super(nodeI1, nodeI2, nodeI3);

  @override
  Future<List<O>> process(
    List<_T> input1,
    List<_T> input2,
    List<_T> input3,
  ) async =>
      // We need to copy items, otherwise operators may modify parents operators items
      // TODO: real deep copy, this is a shallow copy
      List.of(input1).map((e) {
        final input1Element = Map<String, dynamic>.from(e) as O;
        final joinedIds = input2
            .where((e) => e[jtJoinKey] == input1Element['id'])
            .map((e) => e[jtValueKey])
            .toList();
        final joinedItems = joinedIds
            .map((joinId) => Map.from(input3.firstWhere(
                  (e) => e['id'] == joinId,
                )))
            .toList();
        input1Element[joinKey] = joinedItems;
        return input1Element;
      }).toList();
}
