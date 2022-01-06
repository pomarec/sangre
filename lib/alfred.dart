import 'dart:convert';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';

import 'nodes/node.dart';
import 'nodes/operators/diffed.dart';

extension Sangre on Alfred {
  sangre(String path, Node node) async {
    get(
      '/ws$path',
      (req, res) => WebSocketSession(
        onOpen: (ws) => node.stream.map(json.encode).listen(ws.send),
      ),
    );

    final nodeDiffed = await Diffed(node);
    get(
      '/ws$path-diffed',
      (req, res) => WebSocketSession(onOpen: (ws) {
        ws.send(json.encode(nodeDiffed.lastValue));
        nodeDiffed.stream.skip(1).map(json.encode).listen(ws.send);
      }),
    );
  }
}
