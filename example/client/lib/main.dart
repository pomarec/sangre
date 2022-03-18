import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'users-diffed.dart';
import 'users.dart';

final showDiffed = true;

void main() {
  runApp(
    MaterialApp(
      title: 'Sangre realtime example : my friends have bookmarked places',
      theme: FlexThemeData.light(scheme: FlexScheme.redWine),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.redWine),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Sangre client example'),
            bottom: TabBar(
              tabs: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text("Consolidated data streaming"),
                ),
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text("Diffs of data streaming"),
                ),
              ],
            ),
          ),
          body: TabBarView(children: [
            UsersList(),
            UsersDiffedList(),
          ]),
        ),
      ),
    ),
  );
}
