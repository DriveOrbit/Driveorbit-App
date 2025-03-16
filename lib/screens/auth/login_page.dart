import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> login(String email, String password) async {
    // Reset error message and show loading
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Check if email and password are not empty
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = "Email and password cannot be empty";
          _isLoading = false;
        });
        return;
      }

      // For development/testing purposes - use mock login if you want to bypass Firebase
      // Comment this out when Firebase is properly configured
      if (email == "test@example.com" ||
          email == "chamikaradimuth22@gmail.com") {
        await _mockSuccessfulLogin(email);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        }
        return;
      }

      // Attempt login with Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // After successful login, fetch and store user details
        debugPrint('Login successful: ${userCredential.user!.uid}');
        await _fetchAndStoreUserDetails(userCredential.user!.uid, email);

        // Navigate to appropriate dashboard using named route
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = _getFirebaseAuthErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Unknown Error: $e');

      // Development mode - automatically use mock login without showing error
      // In production, you would want to show the error and not proceed
      await _mockSuccessfulLogin(email);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Use this for development/testing only
  Future<void> _mockSuccessfulLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', 'mock-uid-123');
    await prefs.setString('user_email', email);
    await prefs.setString('user_firstName', 'Chamikara');
    await prefs.setString('user_lastName', 'Kodithuwakku');
    await prefs.setString('user_profilePicture',
        'https://i.pravatar.cc/300'); // Using placeholder image service for testing
  }

  Future<void> _fetchAndStoreUserDetails(String uid, String email) async {
    // In a real app, you would fetch this from Firestore or your backend
    final prefs = await SharedPreferences.getInstance();

    // Store user details
    await prefs.setString('user_id', uid);
    await prefs.setString('user_email', email);
    await prefs.setString('user_firstName', 'Chamikara');
    await prefs.setString('user_lastName', 'Kodithuwakku');
    await prefs.setString('user_profilePicture',
        'https://i.pravatar.cc/300'); // Better placeholder than the Google search URL
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please check your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Empower',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: ' Your Fleet,\nElevate Your Edge',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B59A1),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 70),
              const Text(
                'Enter your email to get started:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(178, 255, 255, 255),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromARGB(189, 255, 255, 255),
                      ),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter your password:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(178, 255, 255, 255),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color.fromARGB(189, 255, 255, 255),
                      ),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: const Color.fromARGB(55, 255, 255, 255),
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => login(
                            _emailController.text,
                            _passwordController.text,
                          ),
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(
                      color: Color.fromARGB(27, 255, 255, 255),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Let\'s Drive!'),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
