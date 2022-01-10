import 'package:flutter/material.dart';

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
        footer: date?.toString(),
        child: Column(
          children: users
              .map(
                (user) => Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 23,
                        child: Text(
                          user['users']['id'].toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      Text(
                        user['users']['name'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
}
