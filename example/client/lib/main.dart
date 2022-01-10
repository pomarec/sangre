import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'users-diffed.dart';
import 'users.dart';

final showDiffed = true;

void main() {
  runApp(
    MaterialApp(
      title: 'Sangre over websocket example',
      theme: FlexThemeData.light(scheme: FlexScheme.redWine),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.redWine),
      home: showDiffed ? UsersDiffedList() : UsersList(),
    ),
  );
}
