import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page1.dart';
import 'package:driveorbit_app/Screens/form/page2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DriveOrbit',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => PhotoUploadPage(),
        '/mileage': (context) => MileageForm(),
      },
    );
  }
}
