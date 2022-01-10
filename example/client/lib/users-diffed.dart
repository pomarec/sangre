import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:json_patch/json_patch.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'widgets.dart';

class UsersDiffedList extends StatefulWidget {
  const UsersDiffedList({Key? key}) : super(key: key);

  @override
  State<UsersDiffedList> createState() => _UsersDiffedListState();
}

class _UsersDiffedListState extends State<UsersDiffedList> {
  final usersDiffedStream = BehaviorSubject<Map<String, dynamic>>();
  StreamSubscription? _websocketSubscription;

  bool get isConnected => _websocketSubscription != null;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  _connect() {
    _websocketSubscription = _buildUsersStream().listen(usersDiffedStream.add);
  }

  _disconnect() {
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
  }

  Stream<Map<String, dynamic>> _buildUsersStream() =>
      WebSocketChannel.connect(Uri.parse(
        'ws://127.0.0.1:3000/ws/users-diffed?from=${usersDiffedStream.valueOrNull?['revision'] ?? 0}',
      ))
          .stream
          .cast<String>()
          .map(json.decode)
          .foldStream<Map<String, dynamic>>(
            usersDiffedStream.valueOrNull ??
                {
                  'users': <Map>[],
                  'revision': 0,
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
          );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Sangre over websocket example'),
        ),
        body: SingleChildScrollView(
          child: StreamBuilder(
            stream: usersDiffedStream.accumulate(),
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
          ),
        ),
        persistentFooterButtons: [
          FloatingActionButton(
            onPressed: () => setState(
              () => isConnected ? _disconnect() : _connect(),
            ),
            tooltip: isConnected ? 'disconnect' : 'connect',
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: isConnected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            child: Icon(isConnected ? Icons.cloud_done : Icons.cloud_off),
          ),
          FloatingActionButton(
            onPressed: () => get(Uri.parse(
              "http://localhost:3000/addUser",
            )),
            tooltip: 'Add user',
            child: Icon(Icons.add),
          ),
        ],
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
