import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_patch/json_patch.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UsersDiffedList extends StatefulWidget {
  const UsersDiffedList({Key? key}) : super(key: key);

  @override
  State<UsersDiffedList> createState() => _UsersDiffedListState();
}

class _UsersDiffedListState extends State<UsersDiffedList> {
  late Stream<List<Map<String, dynamic>>> usersDiffedStream;
  List<List> usersAndDiffs = []; // [users, diffs, users, diff, users, ...}

  @override
  void initState() {
    super.initState();
    final channel = WebSocketChannel.connect(Uri.parse(
      'ws://localhost:3000/users-diffed',
    ));
    final usersDiffedStream =
        channel.stream.cast<String>().map(json.decode).asBroadcastStream();
    usersDiffedStream.first.then((initialUsers) {
      print(initialUsers);
      setState(() {
        usersAndDiffs.add(initialUsers);
      });
      usersDiffedStream.listen((newDiffs) {
        setState(() {
          final currentUsers = usersAndDiffs.last;
          usersAndDiffs.add(newDiffs);
          usersAndDiffs.add(JsonPatch.apply(
            currentUsers,
            (newDiffs as List).cast<Map<String, dynamic>>(),
          ));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: usersAndDiffs
            .asMap()
            .entries
            .map(
              (entry) => entry.key % 2 == 0
                  ? entry.value.map(
                      (user) => Text(
                        '[${user['users']['id']}] ${user['users']['name']}',
                        // style: Theme.of(context).textTheme.headline4,
                      ),
                    )
                  : [
                      Text("+"),
                      Text(entry.value.toString()),
                      Text("="),
                    ],
            )
            .expand((e) => e)
            .toList(),
      );
}
