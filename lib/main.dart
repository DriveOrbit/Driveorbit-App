import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/otp_page.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix for potential OpenGL issues
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Store essential user data
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_firstName', 'Chamikara');
    await prefs.setString('user_lastName', 'Kodithuwakku');
    await prefs.setString('user_email', 'tempmail@gmail.com');
    await prefs.setString('user_profilePicture',
        'https://ui-avatars.com/api/?name=Chamikara&background=random');
    debugPrint('✅ Pre-populated SharedPreferences with data');
  } catch (e) {
    debugPrint('❌ SharedPreferences error: $e');
  }

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase core initialized');

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore settings configured');
    } catch (e) {
      debugPrint('❌ Firestore settings error: $e');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Wrap the app in an error handler
  runApp(const MyErrorHandler(child: MyApp()));
}

// Error handler to catch and report Flutter errors
class MyErrorHandler extends StatelessWidget {
  final Widget child;

  const MyErrorHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      return Material(
        child: Container(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text('Exit App', style: TextStyle(color: Colors.blue)),
              )
            ],
          ),
        ),
      );
    };
    return child;
  }
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
          debugShowCheckedModeBanner: false,
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
          // Global error handling
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child ?? Container(),
            );
          },
          // ...existing code...
        );
      },
    );
  }
}
