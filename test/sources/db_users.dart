import 'dart:math';

import '../../bin/nodes/node.dart';

class User {
  int id;
  String name;
  List<User>? friends;

  User(this.id, this.name, [this.friends]);
}

class DBUsersSource extends Node<List<User>> {
  final List<User> _state = [];
  int _nextUserId = 0;

  DBUsersSource() : super();

  @override
  onCreate() async {
    for (int i = 0; i < 4; i++) {
      insertUser();
    }
  }

  insertUser() {
    _state.add(User(_nextUserId++, _getRandomString()));
    streamController.add(
      List.from(_state),
    );
  }
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String _getRandomString([int length = 15]) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(
          _rnd.nextInt(_chars.length),
        ),
      ),
    );
