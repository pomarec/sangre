import 'package:sangre/nodes/operators/join_many_to_many.dart';
import 'package:sangre/sangre.dart';
import 'package:test/test.dart';

void main() {
  test('Join node', () async {
    final ListSource<Map<String, dynamic>> usersDBSource =
        await ListSource<Map<String, dynamic>>();
    _users.cast<Map<String, dynamic>>().forEach(usersDBSource.insertRow);

    final ListSource<Map<String, dynamic>> followedDBSource =
        await ListSource<Map<String, dynamic>>();
    _followed.cast<Map<String, dynamic>>().forEach(followedDBSource.insertRow);

    final JoinManyToMany<Map<String, dynamic>> chain = await JoinManyToMany(
      usersDBSource,
      'followed',
      followedDBSource,
      'user_id',
      'followed_id',
      usersDBSource,
    );

    expect(chain.stream.valueOrNull, isNot(null));

    expect(
      chain.stream.value[1]['followed'][0],
      equals(usersDBSource.stream.value[2]),
    );
  });

  test('Join node & source change', () async {
    final ListSource<Map<String, dynamic>> usersDBSource =
        await ListSource<Map<String, dynamic>>();
    _users.cast<Map<String, dynamic>>().forEach(usersDBSource.insertRow);

    final ListSource<Map<String, dynamic>> followedDBSource =
        await ListSource<Map<String, dynamic>>();
    _followed.cast<Map<String, dynamic>>().forEach(followedDBSource.insertRow);

    final JoinManyToMany<Map<String, dynamic>> chain = await JoinManyToMany(
      usersDBSource,
      'followed',
      followedDBSource,
      'user_id',
      'followed_id',
      usersDBSource,
    );

    expect(chain.stream.valueOrNull, isNot(null));

    followedDBSource.insertRow({
      'user_id': 4,
      'followed_id': 1,
    });

    await chain.stream.first;

    expect(
      chain.stream.value[4]['followed'][1],
      equals(usersDBSource.stream.value[1]),
    );
  });
}

final _users = [
  {
    'id': 0,
    'name': 'kiko',
  },
  {
    'id': 1,
    'name': 'alfred',
  },
  {
    'id': 2,
    'name': 'maurice',
  },
  {
    'id': 3,
    'name': 'oliv',
  },
  {
    'id': 4,
    'name': 'josianne',
  },
];

final _followed = [
  {
    'user_id': 0,
    'followed_id': 1,
  },
  {
    'user_id': 2,
    'followed_id': 1,
  },
  {
    'user_id': 1,
    'followed_id': 2,
  },
  {
    'user_id': 3,
    'followed_id': 1,
  },
  {
    'user_id': 4,
    'followed_id': 3,
  },
  {
    'user_id': 3,
    'followed_id': 4,
  },
];
