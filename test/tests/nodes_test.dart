// @Timeout(Duration(seconds: 10))
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:sangre/sangre.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
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
      (Iterable a) async => a.length,
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
        () => a.length,
      ),
      await GrowingListSource(3),
    );
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
    final ListSource<Tuple2<int, String>> usersDBSource =
        await ListSource<Tuple2<int, String>>();

    for (var i = 0; i < 4; i++)
      usersDBSource.insertRow(
        Tuple2(i, randomString()),
      );

    final intSource = await GrowingListSource(3);
    final chain = await NodeOperator2Input(
      (List<Tuple2<int, String>> users, Iterable b) async =>
          users.length + b.length,
      usersDBSource,
      intSource,
    );

    expect(
      chain.stream,
      emitsInOrder([5, 6, 7]),
    );

    await intSource.streamController.last;

    usersDBSource.insertRow(
      Tuple2(4, randomString()),
    );
    expect(
      chain.stream,
      emitsInOrder([7, 8]),
    );
  });

  test('Join node', () async {
    final ListSource<Map<String, dynamic>> usersDBSource =
        await ListSource<Map<String, dynamic>>();
    for (var i = 0; i < 4; i++) {
      usersDBSource.insertRow({
        'id': i,
        'name': randomString(),
        'friend': 4 - 1 - i,
      });
    }
    expect(usersDBSource.stream.valueOrNull, isNot(null));

    final chain = await JoinOneToOne(
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
    final ListSource<Map<String, dynamic>> usersDBSource =
        await ListSource<Map<String, dynamic>>();
    for (var i = 0; i < 4; i++) {
      usersDBSource.insertRow({
        'id': i,
        'name': randomString(),
        'friend': 4 - 1 - i,
      });
    }

    final chain = await JoinOneToOne(
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
