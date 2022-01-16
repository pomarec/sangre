// @Timeout(Duration(seconds: 10))

import 'package:sangre/sangre.dart';
import 'package:test/test.dart';

void main() {
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
