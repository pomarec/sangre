import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'users-diffed.dart';
import 'users.dart';

final showDiffed = true;

void main() {
  runApp(
    MaterialApp(
      title: 'Sangre over websocket example',
      theme: FlexThemeData.light(scheme: FlexScheme.redWine),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.redWine),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sangre over websocket example'),
        ),
        body: SingleChildScrollView(
          child: showDiffed ? UsersDiffedList() : UsersList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => get(Uri.parse(
            "http://localhost:3000/addUser",
          )),
          tooltip: 'Add user',
          child: Icon(Icons.add),
        ),
      ),
    ),
  );
}
