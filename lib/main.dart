import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page1.dart'; // Import the first page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'Form App',
      theme: ThemeData.dark(),
      home: PhotoUploadPage(), // Ensure this class exists in page1.dart
    );
  }
}

class PhotoUploadPage {}
