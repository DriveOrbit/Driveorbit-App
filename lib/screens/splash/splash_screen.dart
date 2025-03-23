import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('✅ User already logged in: ${currentUser.email}');
        await _ensureUserDataIsCached(currentUser);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/driver-dashboard');
        }
      } else {
        debugPrint('🔑 No user logged in, going to login screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _ensureUserDataIsCached(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedFirstName = prefs.getString('user_firstName');

      if (cachedFirstName == null || cachedFirstName.isEmpty) {
        debugPrint(
            '⚠️ User data not found in cache, fetching from Firestore...');

        final userDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          await _cacheUserData(prefs, user, userData);
        } else {
          debugPrint('⚠️ No user document found in Firestore');
        }
      } else {
        debugPrint('✅ Using cached user data');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring cached data: $e');
    }
  }


  Future<void> _cacheUserData(
      SharedPreferences prefs, User user, Map<String, dynamic> userData) async {
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setString(
        'user_firstName', userData['firstName']?.toString() ?? '');
    await prefs.setString(
        'user_lastName', userData['lastName']?.toString() ?? '');

    final profilePic = userData['profilePicture']?.toString() ?? '';
    if (profilePic.isNotEmpty) {
      await prefs.setString('user_profilePicture', profilePic);
    } else {
      final name = userData['firstName']?.toString() ??
          (user.email?.split('@')[0] ?? '');
      await prefs.setString('user_profilePicture',
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random');
    }

    debugPrint('✅ User data cached successfully');
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to better match the image
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo sized to match the image better
                            Image.asset(
                              'assets/logo/Driveorbit_text.png',
                              width: screenHeight * 0.40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 60),
                            // Loading animation
                            LoadingAnimationWidget.dotsTriangle(
                              color: const Color(0xFF54C1D5),
                              size: 60,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SlideTransition(
              position: _slideAnimation,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  'Your Fleet, Your Edge',
                  style: TextStyle(
                    color: Color.fromARGB(148, 255, 255, 255),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

