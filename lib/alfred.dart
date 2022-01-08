import 'dart:convert';

import 'package:alfred/alfred.dart';
// ignore: implementation_imports
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:postgres/postgres.dart';

import 'nodes/node.dart';
import 'nodes/operators/diffed.dart';

extension Sangre on Alfred {
  sangre(String path, Node node, PostgreSQLConnection postgresClient) async {
    get(
      '/ws$path',
      (req, res) => WebSocketSession(
        onOpen: (ws) => node.stream.map(json.encode).listen(ws.send),
      ),
    );

    final Diffed nodeDiffed = await Diffed(node, postgresClient);
    get(
      '/ws$path-diffed',
      (req, res) => WebSocketSession(onOpen: (ws) {
        final fromRevision = int.tryParse(
          req.uri.queryParameters['from'] ?? "0",
        );
        nodeDiffed.diffsFromRevision(fromRevision).then((diffs) {
          ws.send(json.encode(diffs));
          nodeDiffed.stream.skip(1).map(json.encode).listen(ws.send);
        });
      }),
    );
  }
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
}
