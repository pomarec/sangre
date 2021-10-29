import 'package:test/test.dart';

import '../bin/operators/count.dart';
import '../bin/sources/growing_list.dart';
import '../bin/vena.dart';

void main() {
  test('Count operator', () {
    final co = CountOperator();
    final res = co.process([1, 3, 4]);
    expect(res, equals(3));
  });

  test('Growling list source', () {
    final gls = GrowingListSouce(3);
    expect(
      gls.egress,
      emitsInOrder([
        [0],
        [0, 1],
        [0, 1, 2],
        emitsDone
      ]),
    );
  });

  test('Combine growing list source with count operator', () {
    final veina = Vena(GrowingListSouce(3), [CountOperator()]);
    expect(
      veina.egress,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });
}
