// @Timeout(Duration(seconds: 10))
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:sangre/sangre.dart';
import 'package:test/test.dart';

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
  }, timeout: Timeout(Duration(seconds: 3)));

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

  test('Node chaining without await', () async {
    final chain = await NodeOperator1Input(
      (Iterable a) async => a.length,
      GrowingListSource(3),
    );
    expect(
      chain.stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });
}
