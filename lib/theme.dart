// theme.dart
// MyApp has been moved to app.dart
// Add your custom ThemeData here if needed in the future

import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    useMaterial3: true,
  );
}
