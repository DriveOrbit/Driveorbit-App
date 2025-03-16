import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/otp_page.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(449, 973),
      builder: (context, child) {
        return MaterialApp(
            title: 'DriveOrbit',
            theme: darkTheme,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(),
              '/otp': (context) => const OtpPage(),
              '/dashboard': (context) => const DashboardDriverPage(),
              '/admin-dashboard': (context) => const DashboardDriverPage(),
              '/driver-dashboard': (context) => const DashboardDriverPage()
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Text('No route defined for ${settings.name}'),
                  ),
                ),
              );
            });
      },
    );
  }
}
