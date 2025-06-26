import 'package:flutter/material.dart';
import '../Screens/auth/login_page.dart';
import '../Screens/auth/forgot_password_page.dart';
import '../Screens/auth/otp_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginPage(),
  // '/signup': (context) => const SignupPage(),
  '/forgot-password': (context) => const ForgotPasswordPage(),
  '/otp': (context) => const OtpPage(),
};
