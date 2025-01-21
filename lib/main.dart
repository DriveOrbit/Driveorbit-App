import 'package:flutter/material.dart';
import 'app/routes.dart';
import 'app/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveOrbit App',
      theme: darkTheme, // Apply the dark theme
      initialRoute: '/login',
      routes: appRoutes,
    );
  }
}
