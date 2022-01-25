import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hovering/hovering.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import 'infobox.dart';

const _radius = 4.0;

const lightRed = Color(0x4D9B1B30);

class UsersWidget extends StatefulWidget {
  final String? title;
  final List users;
  final DateTime? date;
  final int? revision;

  const UsersWidget({
    Key? key,
    this.title,
    required this.users,
    this.date,
    this.revision,
  }) : super(key: key);

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget> {
  bool showJSON = false;

  @override
  Widget build(BuildContext context) => InfoBoxWidget(
        title: (widget.title ?? "") +
            (widget.revision != null ? ' : [rev: ${widget.revision}]' : ' :'),
        accessoryChild: GestureDetector(
          onTap: () => setState(() {
            showJSON = !showJSON;
          }),
          child: Text("toggle json",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              )),
        ),
        footer: widget.date != null ? DateFormat().format(widget.date!) : null,
        child: showJSON
            ? Text(JsonEncoder.withIndent('  ').convert(widget.users))
            : Wrap(
                children: widget.users
                    .map(
                      (user) => Container(
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(10),
                        width: 185,
                        height: 170,
                        decoration: BoxDecoration(
                          color: lightRed,
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () => get(Uri.parse(
                                  "http://127.0.0.1:3000/unfollow?id=${user['id']}",
                                )),
                                child: HoverCrossFadeWidget(
                                  duration: Duration(milliseconds: 500),
                                  firstChild: CircleAvatar(
                                    radius: 30,
                                    child: Center(child: Text(user['name'])),
                                  ),
                                  secondChild: CircleAvatar(
                                    radius: 30,
                                    child: Center(
                                      child: Icon(Icons.delete),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('Likes :'),
                            SizedBox(height: 5),
                            ...user['places']
                                .map(
                                  (place) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        size: 12,
                                      ),
                                      SizedBox(width: 5),
                                      Text(place['name']),
                                      Expanded(child: Container()),
                                      ...List.generate(
                                        place['occupation'] ?? 0,
                                        (_) => Icon(
                                          Icons.person,
                                          size: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList()
                                .cast<Widget>(),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      );
}
