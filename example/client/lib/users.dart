import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'widgets/users.dart';

class UsersList extends StatefulWidget {
  const UsersList({Key? key}) : super(key: key);

  @override
  State<UsersList> createState() => _UsersListState();
}

typedef UserType = Map<String, dynamic>;

class _UsersListState extends State<UsersList> {
  late Stream<Map<String, dynamic>> usersStream;

  @override
  void initState() {
    super.initState();
    usersStream = WebSocketChannel.connect(Uri.parse(
      'ws://127.0.0.1:3000/ws/followeds',
    ))
        .stream
        .cast<String>()
        .map(json.decode)
        .map((e) => e['followeds'])
        .map((e) => (e as List).cast<UserType>())
        .map((e) => {
              'followeds': e,
              'date': DateTime.now(),
            });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: usersStream,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) =>
            UsersWidget(
          title: 'Friends',
          users: snapshot.data?['followeds'] as List<UserType>? ?? [],
          date: snapshot.data?['date'],
        ),
      );
}
