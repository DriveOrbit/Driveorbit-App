import 'package:driveorbit_app/Screens/form/page2';
import 'package:flutter/material.dart';
// Import your form file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'Form',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: Text("Form")),
        body: SingleChildScrollView(
          child: MileageForm(),
        ),
      ),
    );
  }
}
