import 'package:flutter/material.dart';

import '../utils.dart';

const lightRed = Color(0x4D9B1B30);

class JSONWidget extends StatelessWidget {
  final dynamic json;

  const JSONWidget({Key? key, this.json}) : super(key: key);

  @override
  Widget build(BuildContext context) => json is List
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (json as List)
              .map(
                (e) => JSONWidget(json: e),
              )
              .toList(),
        )
      : json is Map
          ? Column(
              children: [
                _buildAttributes(
                  context,
                  (json as Map<String, dynamic>).entries.where(
                        (e) => !(e.value is Map || e.value is List),
                      ),
                ),
                ..._buildChildren(
                  context,
                  (json as Map<String, dynamic>)
                      .entries
                      .where((e) => e.value is Map),
                ),
                ..._buildChildren(
                  context,
                  (json as Map<String, dynamic>)
                      .entries
                      .where((e) => e.value is List),
                )
              ],
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                json.toString(),
              ),
            );

  Widget _buildAttributes(
    BuildContext context,
    Iterable<MapEntry> attributes,
  ) =>
      Row(
        children: [
          Text("- "),
          ...attributes
              .sorted((a, b) => a.key.compareTo(b.key))
              .map(
                (e) => JSONWidget(json: e.value),
              )
              .toList(),
        ],
      );

  Iterable<Widget> _buildChildren(
    BuildContext context,
    Iterable<MapEntry> children,
  ) =>
      children.sorted((a, b) => a.key.compareTo(b.key)).map(
            (e) => Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 10),
                    Text("- "),
                    JSONWidget(json: e.key),
                    Text(":"),
                    if (!(e.value is List)) JSONWidget(json: e.value),
                  ],
                ),
                if (e.value is List)
                  Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: JSONWidget(json: e.value),
                  ),
              ],
            ),
          );
}
