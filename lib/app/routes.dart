import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/password_reset.dart';
import '../screens/auth/forgot_password_page.dart';
import '../screens/auth/otp_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginPage(),
  '/signup': (context) => const SignupPage(),
  '/forgot-password': (context) => const ForgotPasswordPage(),
  '/otp': (context) => const OtpPage(),
};
