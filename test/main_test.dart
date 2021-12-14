import 'package:test/test.dart';

import '../bin/nodes/operator_node.dart';
import '../bin/nodes/operators.dart';
import '../bin/nodes/sources/growing_list.dart';

void main() {
  test('Count operator', () {
    final res = count([1, 3, 4]);
    expect(res, equals(3));
  });

  test('Growling list source', () {
    final gls = GrowingListSource(3);
    expect(
      gls.stream,
      emitsInOrder([
        [0],
        [0, 1],
        [0, 1, 2],
        emitsDone
      ]),
    );
  });

  test('Combine growing list source with count operator', () {
    final chain = NodeOperator1Input(
        (Iterable a) async => count(a), GrowingListSource(3));
    expect(
      chain.stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });

  test('Combine growing list source with an async operator', () {
    final chain = NodeOperator1Input(
        (Iterable a) => Future.delayed(
              Duration(seconds: 1),
              () => count(a),
            ),
        GrowingListSource(3));
    expect(
      chain.stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });

  test('Combine two growing list source with count operator', () {
    final chain = NodeOperator2Input(
      (Iterable a, Iterable b) async => a.length + b.length,
      GrowingListSource(3),
      GrowingListSource(4),
    );
    expect(
      chain.stream,
      emitsInOrder([2, 3, 4, 5, 6, 7, emitsDone]),
    );
  });
}



// class User {}

// Stream<List<User>> getUsers(String group) 

//   => DB('users').to(Filter(group)).to(Join('places')).to(FetchPlaceDetail());

