import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_patch/json_patch.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'widgets.dart';

class UsersDiffedList extends StatefulWidget {
  const UsersDiffedList({Key? key}) : super(key: key);

  @override
  State<UsersDiffedList> createState() => _UsersDiffedListState();
}

class _UsersDiffedListState extends State<UsersDiffedList> {
  late Stream<List<Map<String, dynamic>>> usersDiffedStream;

  @override
  void initState() {
    super.initState();
    usersDiffedStream = _buildUsersStream();
  }

  Stream<List<Map<String, dynamic>>> _buildUsersStream([
    int lastRevision = 0,
    List<Map>? lastUsers,
  ]) =>
      WebSocketChannel.connect(Uri.parse(
        'ws://127.0.0.1:3000/ws/users-diffed?from=$lastRevision',
      ))
          .stream
          .cast<String>()
          .map(json.decode)
          .foldStream<Map<String, dynamic>>(
        {
          'users': lastUsers ?? <Map>[],
          'revision': lastRevision,
        },
        (previous, diffs) => {
          'lastRevision': previous['revision'],
          'revision': diffs['revision'],
          'diffs': diffs['diffs'],
          'users': (JsonPatch.apply(
            previous['users'],
            (diffs['diffs'] as List).cast<Map<String, dynamic>>(),
            strict: false,
          ) as List)
              .cast<Map<String, dynamic>>(),
          'date': DateTime.now(),
        },
      ).accumulate();

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: usersDiffedStream,
        builder: (
          context,
          AsyncSnapshot snapshot,
        ) =>
            Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: (snapshot.data as List<Map<String, dynamic>>? ??
                  <Map<String, dynamic>>[])
              .map(
                (Map<String, dynamic> e) => [
                  if (e['diffs'] != null) ...[
                    if (e['lastRevision'] != 0) Chip(label: Text("+")),
                    InfoBoxWidget(
                      title: "Diff",
                      child: Text(e['diffs'].toString()),
                      footer:
                          "revision ${e['lastRevision']} => ${e['revision']}",
                    ),
                    Chip(label: Text("=")),
                  ],
                  UsersWidget(
                    revision: e['revision'],
                    users: e['users'] as List<Map>,
                    date: DateTime.now(),
                  ),
                ],
              )
              .expand((e) => e)
              .toList(),
        ),
      );
}

extension FoldStream<T> on Stream<T> {
  Stream<S> foldStream<S>(
    S initialValue,
    S Function(S previous, T element) combine,
  ) {
    S lastValue = initialValue;
    return map((T e) {
      lastValue = combine(lastValue, e);
      return lastValue;
    });
  }

  Stream<List<T>> accumulate() {
    final lastValue = List<T>.empty(growable: true);
    return map((T e) {
      lastValue.add(e);
      return List.from(lastValue);
    });
  }
}
