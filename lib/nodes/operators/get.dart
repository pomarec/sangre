import './join_many_to_many.dart';
import '../node.dart';

// TODO : write tests
class Get<T extends Map<String, dynamic>> extends Node1Input<List<T>, T>
    with JoinableOne<T> {
  final String key;

  /// If value is null, first item of nodeI1 will be ouputed
  final dynamic value;

  Get(Node<List<T>> nodeI1, this.key, this.value) : super(nodeI1);

  @override
  Future<T> process(List<T> input1) async =>
      input1.where((e) => value == null || e[key] == value).first;

  @override
  String get tableName => 'users';
}

mixin Getable<T extends Map<String, dynamic>> on Node<List<T>> {
  Get<T> get(String key, dynamic value) => Get(this, key, value);
}
