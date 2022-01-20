import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'utils.dart';

const _radius = 4.0;

const lightRed = Color(0x4D9B1B30);

class InfoBoxWidget extends StatelessWidget {
  final String? title;
  final Widget child;
  final String? footer;

  const InfoBoxWidget({
    Key? key,
    this.title,
    this.footer,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            if (title != null)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_radius),
                        topRight: Radius.circular(_radius),
                      ),
                    ),
                    child: Text(
                      title!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: lightRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_radius),
                  topRight: Radius.circular(_radius),
                ),
              ),
              child: child,
            ),
            if (footer != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    color: Theme.of(context).colorScheme.primary,
                    child: Text(
                      footer!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
}

class UsersWidget extends StatelessWidget {
  final List<Map> users;
  final DateTime? date;
  final int? revision;

  const UsersWidget({
    Key? key,
    required this.users,
    this.date,
    this.revision,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => InfoBoxWidget(
        title: revision != null ? 'Users [rev: ${revision}]' : 'Users',
        footer: date != null ? DateFormat().format(date!) : null,
        child: JSONWidget(json: users),
        // Column(
        //   children: users
        //       .map(
        //         (user) => Container(
        //           padding: EdgeInsets.symmetric(vertical: 3),
        //           child: Row(
        //             children: [
        //               Container(
        //                 width: 23,
        //                 child: Text(
        //                   user['id'].toString(),
        //                   style: TextStyle(
        //                     color: Theme.of(context).colorScheme.onBackground,
        //                   ),
        //                 ),
        //               ),
        //               Container(
        //                 height: 12,
        //                 width: 1,
        //                 margin: EdgeInsets.symmetric(horizontal: 10),
        //                 color: Theme.of(context).colorScheme.onBackground,
        //               ),
        //               Text(
        //                 user['name'],
        //                 style: TextStyle(
        //                   color: Theme.of(context).colorScheme.onBackground,
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       )
        //       .toList(),
        // ),
      );
}

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
