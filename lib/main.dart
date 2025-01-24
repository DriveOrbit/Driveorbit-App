import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'app/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveOrbit',
      theme: darkTheme, // Apply the dark theme
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
