import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Add pulse animation for the logo glow effect
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animations
    _animationController.forward();

    // Make it repeat for continuous animation effect
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.repeat(reverse: true);

        // Check auth after initial animation completes
        _checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Add a slight delay to ensure animations complete
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      // Get current Firebase user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('✅ User already logged in: ${currentUser.email}');

        // Make sure we have user data cached
        await _ensureUserDataIsCached(currentUser);

        // Navigate to driver dashboard
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
      // Fallback to login on error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _ensureUserDataIsCached(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if basic user data exists in cache
      final cachedFirstName = prefs.getString('user_firstName');

      if (cachedFirstName == null || cachedFirstName.isEmpty) {
        debugPrint(
            '⚠️ User data not found in cache, fetching from Firestore...');

        // Fetch data from Firestore if not cached
        final userDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;

          // Store user data in cache
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
            // Generate avatar as fallback
            final name = userData['firstName']?.toString() ??
                (user.email?.split('@')[0] ?? '');
            await prefs.setString('user_profilePicture',
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random');
          }

          debugPrint('✅ User data cached successfully');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with rotation, scale, and pulse animations
                  Transform.rotate(
                    angle: math.sin(_rotationAnimation.value) * math.pi / 10,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D6BF8)
                                  .withOpacity(0.3 * _pulseAnimation.value),
                              blurRadius: 20 * _pulseAnimation.value,
                              spreadRadius: 5 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              80), // Half of width/height for circle
                          child: Image.asset(
                            'assets/logo/Driveorbitlogo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.black,
                              child: Icon(
                                Icons.directions_car,
                                size: 100,
                                color: Color(0xFF6D6BF8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Enhanced progress indicator with rotation
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating outer circle
                        Transform.rotate(
                          angle: _animationController.value * 2 * math.pi,
                          child: const CircularProgressIndicator(
                            color: Color(0xFF6D6BF8),
                            strokeWidth: 4,
                            value: null,
                          ),
                        ),
                        // Pulsating inner circle
                        Container(
                          width: 20 * _pulseAnimation.value,
                          height: 20 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF54C1D5).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // App name with slide-up animation
                  Transform.translate(
                    offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                    child: Column(
                      children: [
                        const Text(
                          'DriveOrbit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Drive Smarter, Not Harder',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Loading text with fading animation
                  Opacity(
                    opacity:
                        math.sin(_animationController.value * math.pi).abs(),
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Color(0xFF54C1D5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
