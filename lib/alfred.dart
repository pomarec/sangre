import 'dart:convert';
import 'dart:developer';

import 'package:alfred/alfred.dart';
// ignore: implementation_imports
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:postgres/postgres.dart';
import 'package:sangre/nodes/sources/postgres_table.dart';

import 'nodes/node.dart';
import 'nodes/operators/diffed.dart';

extension Sangre on Alfred {
  sangre(String path, Node node, [PostgreSQLConnection? postgresClient]) async {
    get(
      '/ws$path',
      (req, res) => WebSocketSession(
        onOpen: (ws) => node.stream.map(json.encode).listen(ws.send),
      ),
    );

    PostgreSQLConnection? pgClient = postgresClient;
    if (pgClient == null && node is PostgresTableSource)
      pgClient = node.postgresClient;
    pgClient ??= PostgresTableSource.globalPostgresClient;

    if (pgClient != null) {
      final Diffed nodeDiffed = await Diffed(node, pgClient);
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
    } else
      log("Sangre could not plug the diffed node from $node beacause no postgresClient was provided.");
  }
}
