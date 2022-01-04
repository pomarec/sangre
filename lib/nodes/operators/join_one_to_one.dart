import '../node.dart';

class JoinOneToOne<T extends Map<String, dynamic>>
    extends Node2Input<List<T>, List<T>, List<T>> {
  /// Key of input1 items to match items from input2
  /// Can be a string or a Function(item of input1)
  final dynamic joinKey;

  /// Key of input1 items to populate with matches from input2
  /// Can be a string or a Function(item of input1, matching item of input2)
  final dynamic joinedKey;

  /// Key of input2 items to match with input1 joinKey
  /// Can be a string or a Function(item of input2)
  final dynamic matchingKey;

  JoinOneToOne(
    Node<List<T>> nodeI1,
    this.joinKey,
    Node<List<T>> nodeI2, [
    this.matchingKey = 'id',
    dynamic joinedKey,
  ])  : joinedKey = joinedKey ?? joinKey,
        super(nodeI1, nodeI2);

  @override
  Future<List<T>> process(
    List<T> input1,
    List<T> input2,
  ) async =>
      // We need to copy items, otherwise operators may modify parents operators items
      // TODO: real deep copy, this is a shallow copy
      List.of(input1).map((e) {
        final input1Element = Map<String, dynamic>.from(e) as T;
        final joinValue = _stringOrFunctionGet(input1Element, joinKey);
        if (joinValue != null)
          for (T input2Element in input2)
            if (_stringOrFunctionGet(input2Element, matchingKey) == joinValue) {
              _stringOrFunctionSet(input1Element, joinedKey, input2Element);
              break;
            }
        return input1Element;
      }).toList();

  _stringOrFunctionGet(Map o, dynamic getter) {
    if (getter is String)
      return o[getter];
    else if (getter is Function)
      return getter(o);
    else
      throw StateError("wrong getter $getter");
  }

  _stringOrFunctionSet(Map o, dynamic setter, dynamic v) {
    if (setter is String)
      return o[setter] = v;
    else if (setter is Function)
      return setter(o, v);
    else
      throw StateError("wrong getter $setter");
  }

  // _deepGet(dynamic o, String path) {
  //   final pathList = path.split('.');
  //   if (pathList.isEmpty || path == "") return o;

  //   if (o is List) {
  //     final intPath = int.tryParse(pathList[0]);
  //     if (intPath == null)
  //       throw StateError("You must provide an integer for list _deepGet");
  //     else
  //       return _deepGet(o[intPath], pathList.skip(1).join('.'));
  //   }

  //   if (o is Map) return _deepGet(o[pathList[0]], pathList.skip(1).join('.'));

  //   throw StateError("Can't _deepGet $o");
  // }

  // _deepSet(dynamic o, String path, dynamic v) {
  //   final pathList = path.split('.');
  //   if (pathList.isEmpty || path == "") return o;

  //   if (o is List) {
  //     final intPath = int.tryParse(pathList[0]);
  //     if (intPath == null)
  //       throw StateError("You must provide an integer for list _deepSet");
  //     else if (pathList.length == 1)
  //       return o.replaceRange(intPath, intPath + 1, [v]);
  //     else
  //       return _deepSet(o[intPath], pathList.skip(1).join('.'), v);
  //   }

  //   if (o is Map) {
  //     if (pathList.length == 1)
  //       return o[pathList[0]] = v;
  //     else
  //       return _deepSet(o[pathList[0]], pathList.skip(1).join('.'), v);
  //   }

  //   throw StateError("Can't _deepSet $o");
  // }

  // dynamic _deepCopy(dynamic o) {
  //   if (o is List)
  //     return List.generate(
  //       o.length,
  //       (index) => _deepCopy(o[index]),
  //     );

  //   if (o is Map)
  //     return Map.fromEntries(o.entries.map(
  //       (e) => MapEntry(
  //         e.key,
  //         _deepCopy(e.value),
  //       ),
  //     ));

  //   return o;
  // }
}
