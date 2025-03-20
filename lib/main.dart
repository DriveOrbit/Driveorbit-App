import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/otp_page.dart';
import 'app/theme.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix for potential OpenGL issues
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase core initialized');

    // Remove the setPersistence call as it's not supported on mobile
    // Firebase Auth on mobile platforms keeps the user logged in by default

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore settings configured');

      // Test Firestore permissions early - only check drivers collection
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          final uid = auth.currentUser!.uid;
          await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
          debugPrint('✅ Firestore permissions verified for drivers collection');
        }
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          debugPrint(
              '⚠️ Firestore permission denied. Check security rules for drivers collection');
        }
      }
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

  const MyErrorHandler({super.key, required this.child});

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
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit App',
                    style: TextStyle(color: Colors.blue)),
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
      designSize:
          const Size(449, 973), // Design size based on your design files
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'DriveOrbit',
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          initialRoute: '/splash', // Changed from '/login' to '/splash'
          routes: {
            '/splash': (context) => const SplashScreen(),
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
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child ?? Container(),
            );
          },
        );
      },
      child: const SplashScreen(), // Your initial screen
    );
  }
}
