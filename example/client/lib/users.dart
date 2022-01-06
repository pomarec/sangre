import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UsersList extends StatefulWidget {
  const UsersList({Key? key}) : super(key: key);

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late Stream<List> usersStream;

  @override
  void initState() {
    super.initState();
    final channel = WebSocketChannel.connect(Uri.parse(
      'ws://localhost:3000/ws/users',
    ));
    usersStream = channel.stream.cast<String>().map(json.decode).cast<List>();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: usersStream,
        builder: (context, snapshot) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (snapshot.data as List? ?? [])
              .map((user) => Row(children: [
                    Text(
                      '[${user['users']['id']}] ${user['users']['name']}',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ]))
              .toList(),
        ),
      );
}
