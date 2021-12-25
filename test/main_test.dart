import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:test/test.dart';

import './utils.dart';
import '../bin/nodes/operator_node.dart';
import '../bin/nodes/operators.dart';
import '../bin/nodes/sources/growing_list.dart';
import '../bin/nodes/sources/join_one_to_many.dart';
import 'sources/fake_sql_table.dart';

void main() {
  test('Count operator', () {
    final res = count([1, 3, 4]);
    expect(res, equals(3));
  });

  test('Growling list source', () async {
    final gls = await GrowingListSource(3);
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

  test('Combine growing list source with count operator', () async {
    final chain = await NodeOperator1Input(
      (Iterable a) async => count(a),
      await GrowingListSource(3),
    );
    expect(
      chain.stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });

  test('Combine growing list source with an async operator', () async {
    final chain = await NodeOperator1Input(
        (Iterable a) => Future.delayed(
              Duration(seconds: 1),
              () => count(a),
            ),
        await GrowingListSource(3));
    expect(
      chain.stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });

  test('Combine two growing list source with count operator', () async {
    final chain = await NodeOperator2Input(
      (Iterable a, Iterable b) async => a.length + b.length,
      await GrowingListSource(3),
      await GrowingListSource(4),
    );
    expect(
      chain.stream,
      emitsInOrder([2, 3, 4, 5, 6, 7, emitsDone]),
    );
  });

  test('React properly to source change', () async {
    // This test has no semantic meaning, but tests source propagation
    final usersDBSource = await FakeSQLTableSource<Tuple2<int, String>>();
    final chain = await NodeOperator2Input(
      (List<Tuple2<int, String>> users, Iterable b) async =>
          users.length + b.length,
      usersDBSource,
      await GrowingListSource(3),
    );
    for (var i = 0; i < 4; i++) {
      usersDBSource.insertRow(
        Tuple2(i, randomString()),
      );
    }
    expect(
      chain.stream,
      emitsInOrder([5, 6, 7]),
    );

    await Future.delayed(Duration(seconds: 1));

    usersDBSource.insertRow(
      Tuple2(4, randomString()),
    );
    expect(
      chain.stream,
      emitsInOrder([7, 8]),
    );
  });

  test('Join node', () async {
    final FakeSQLTableSource<Map<String, dynamic>> usersDBSource =
        await FakeSQLTableSource<Map<String, dynamic>>();
    for (var i = 0; i < 4; i++) {
      usersDBSource.insertRow({
        'id': i,
        'name': randomString(),
        'friend': 4 - 1 - i,
      });
    }
    expect(usersDBSource.stream.valueOrNull, isNot(null));

    final chain = await JoinOneToMany(
      usersDBSource,
      'friend',
      usersDBSource,
      'id',
    );

    expect(chain.stream.valueOrNull, isNot(null));

    expect(
      chain.stream.value[1]['friend'],
      equals(usersDBSource.stream.value[2]),
    );
  });

  test('Join node & source change', () async {
    // This test has no semantic meaning, but tests source propagation
    final FakeSQLTableSource<Map<String, dynamic>> usersDBSource =
        await FakeSQLTableSource<Map<String, dynamic>>();
    for (var i = 0; i < 4; i++) {
      usersDBSource.insertRow({
        'id': i,
        'name': randomString(),
        'friend': 4 - 1 - i,
      });
    }

    final chain = await JoinOneToMany(
      usersDBSource,
      'friend',
      usersDBSource,
      'id',
    );

    usersDBSource.insertRow({
      'id': 4,
      'name': randomString(),
      'friend': 3,
    });

    await usersDBSource.stream.first;

    expect(
      chain.stream.value[4]['friend'],
      equals(usersDBSource.stream.value[3]),
    );
  });
}

//   => DB('users').to(Filter(group)).to(Join('places')).to(FetchPlaceDetail());

