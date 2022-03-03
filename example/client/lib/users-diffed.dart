import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_patch/json_patch.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'utils.dart';
import 'widgets/infobox.dart';
import 'widgets/users.dart' hide lightRed;

class UsersDiffedList extends StatefulWidget {
  const UsersDiffedList({Key? key}) : super(key: key);

  @override
  State<UsersDiffedList> createState() => _UsersDiffedListState();
}

class _UsersDiffedListState extends State<UsersDiffedList> {
  final usersDiffedStream = BehaviorSubject<Map<String, dynamic>>();
  late final usersDiffedStreamAccumulated = usersDiffedStream.accumulate();
  StreamSubscription? _websocketSubscription;

  bool get isConnected => _websocketSubscription != null;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  _connect() {
    _websocketSubscription = _buildUsersStream().listen(usersDiffedStream.add);
    usersDiffedStream.add(Map.from(usersDiffedStream.valueOrNull ?? {})
      ..addAll({
        'connection': true,
        'date': DateTime.now(),
      }));
  }

  _disconnect() {
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
    usersDiffedStream.add(Map.from(usersDiffedStream.valueOrNull ?? {})
      ..addAll({
        'disconnection': true,
        'date': DateTime.now(),
      }));
  }

  Stream<Map<String, dynamic>> _buildUsersStream() =>
      WebSocketChannel.connect(Uri.parse(
        'ws://127.0.0.1:3000/ws/followeds-diffed-${usersDiffedStream.valueOrNull?['revision'] ?? 0}',
      ))
          .stream
          // .map((e) {
          //   print(e);
          //   return e;
          // })
          .cast<String>()
          .map(json.decode)
          .foldStream<Map<String, dynamic>>(
            usersDiffedStream.valueOrNull ??
                {
                  'data': Map<String, dynamic>(),
                  'revision': 0,
                },
            (previous, diffs) => {
              'lastRevision': previous['revision'],
              'revision': diffs['revision'],
              'diffs': diffs['diffs'],
              'data': JsonPatch.apply(
                previous['data'],
                (diffs['diffs'] as List).cast<Map<String, dynamic>>(),
                strict: false,
              ),
              'date': DateTime.now(),
            },
          );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Sangre diffs over websocket example'),
        ),
        body: SingleChildScrollView(
          child: StreamBuilder(
            stream: usersDiffedStreamAccumulated,
            builder: (
              context,
              AsyncSnapshot snapshot,
            ) =>
                Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: (snapshot.data as List<Map<String, dynamic>>? ??
                      <Map<String, dynamic>>[])
                  .map(
                    (e) => e['connection'] != null
                        ? [_buildSeparator(context, true, e['date'])]
                        : e['disconnection'] != null
                            ? [_buildSeparator(context, false, e['date'])]
                            : [
                                if (e['diffs'] != null) ..._buildDiffs(e),
                                UsersWidget(
                                  title: 'Friends',
                                  revision: e['revision'],
                                  users: e['data']['followeds'],
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
        ],
      );

  List<Widget> _buildDiffs(Map<String, dynamic> e) => [
        if (e['lastRevision'] != 0) Chip(label: Text("+")),
        Opacity(
          opacity: 0.6,
          child: InfoBoxWidget(
            title: "Diff",
            child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  JsonEncoder.withIndent('  ').convert(e['diffs']),
                ),
              ),
            ),
            footer: "revision ${e['lastRevision']} => ${e['revision']}",
          ),
        ),
        Chip(label: Text("=")),
      ];

  Widget _buildSeparator(BuildContext context, bool connected, DateTime date) =>
      Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: lightRed,
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                connected ? Icons.cloud_done : Icons.cloud_off,
                color: lightRed,
              ),
            ),
            Expanded(
                child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 10),
                    height: 1,
                    color: lightRed,
                  ),
                ),
                Text(
                  DateFormat().format(date),
                  style: TextStyle(color: lightRed),
                ),
              ],
            )),
          ],
        ),
      );
}
