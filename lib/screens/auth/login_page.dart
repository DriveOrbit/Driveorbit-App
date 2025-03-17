import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isLoading = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Animation controller for button press effect
  // Making these non-late to avoid LateInitializationError
  AnimationController? _buttonController;
  Animation<double>? _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller immediately
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation immediately
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonController!,
        curve: Curves.easeInOut,
      ),
    );

    // Check for cached credentials (optional auto-fill)
    _checkCachedCredentials();
  }

  Future<void> _checkCachedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    } catch (e) {
      debugPrint('Error loading cached credentials: $e');
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Reset all error messages
  void _resetErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  // Email validation
  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation (must be at least 6 characters)
  bool _isPasswordValid(String password) {
    return password.length >= 6;
  }

  Future<void> login(String email, String password) async {
    // Reset error messages
    _resetErrors();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Basic validation
    if (email.isEmpty) {
      setState(() => _emailError = "Email cannot be empty");
      return;
    } else if (!_isEmailValid(email)) {
      setState(() => _emailError = "Please enter a valid email address");
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = "Password cannot be empty");
      return;
    }

    // Show loading indicator with animation
    setState(() {
      _isLoading = true;
    });
    _buttonController?.forward();

    try {
      debugPrint('Attempting login with email: $email');

      // Attempt login with Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Save email for convenience
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);

        // Store basic authentication info first
        await _storeBasicUserInfo(userCredential.user!);

        // Try to get additional info from Firestore
        await _fetchUserDataFromFirestore(userCredential.user!);

        // Navigate to the dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      _handleFirebaseAuthError(e);
    } catch (e) {
      _handleGenericError(e);
    } finally {
      // Reset button animation and loading state
      if (mounted) {
        _buttonController?.reverse();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle Firebase Auth specific errors
  void _handleFirebaseAuthError(FirebaseAuthException e) {
    setState(() {
      switch (e.code) {
        case 'invalid-email':
          _emailError = 'The email address is not valid';
          break;
        case 'user-not-found':
          _emailError = 'No user found for this email';
          break;
        case 'wrong-password':
          _passwordError = 'Incorrect password';
          break;
        case 'user-disabled':
          _generalError = 'This account has been disabled';
          break;
        case 'too-many-requests':
          _generalError = 'Too many login attempts. Try again later';
          break;
        case 'network-request-failed':
          _generalError = 'Network error. Check your connection.';
          break;
        default:
          _generalError = _getFirebaseAuthErrorMessage(e.code);
      }
    });
  }

  // Handle generic errors including PigeonUserDetails error
  void _handleGenericError(dynamic e) {
    final String errorText = e.toString();
    if (errorText.contains("'List<Object?>") &&
        errorText.contains("'PigeonUserDetails?'")) {
      _handlePigeonUserDetailsError();
    } else {
      debugPrint('❌ Unknown error: $e');
      setState(() {
        _generalError = 'Login failed. Please try again.';
      });
    }
  }

  Future<void> _handlePigeonUserDetailsError() async {
    debugPrint('Detected PigeonUserDetails error, using fallback approach');
    try {
      // Get current user since login might have succeeded despite the error
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _fetchUserDataFromFirestore(currentUser);
        // Navigate to dashboard - login succeeded
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        }
      }
    } catch (authError) {
      debugPrint('❌ Error handling PigeonUserDetails fallback: $authError');
      setState(() {
        _generalError = 'Error retrieving user data. Please try again.';
      });
    }
  }

  // Clean method to fetch and store Firestore data
  Future<void> _fetchUserDataFromFirestore(User user) async {
    try {
      debugPrint('📊 Attempting to fetch Firestore data...');
      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        debugPrint('✅ Found driver document in Firestore!');
        await _storeUserDataFromFirestore(user, userDoc.data()!);
      } else {
        // Document doesn't exist
        debugPrint('⚠️ No driver document found in Firestore for this user ID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No driver profile found. Please contact your administrator.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (firestoreError) {
      _handleFirestoreError(firestoreError);
    }
  }

  void _handleFirestoreError(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      debugPrint('⚠️ Firestore permission denied. Using basic auth info only.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to access user data. Make sure Firestore rules allow access.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      debugPrint('❌ Firestore error: $error');
    }
  }

  // Clean method to store actual user data from Firestore
  Future<void> _storeUserDataFromFirestore(
      User user, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Store essential user info
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email ?? '');

    // Get actual name data from Firestore - using your specific field names
    final firstName = userData['firstName']?.toString() ?? '';
    final lastName = userData['lastName']?.toString() ?? '';

    debugPrint(
        'Storing user data - firstName: $firstName, lastName: $lastName');

    // Store names with fallback if needed
    await prefs.setString('user_firstName', firstName);
    await prefs.setString('user_lastName', lastName);

    // Store profile picture URL directly from Firestore
    final profilePic = userData['profilePicture']?.toString() ?? '';
    if (profilePic.isNotEmpty) {
      await prefs.setString('user_profilePicture', profilePic);
      debugPrint('Stored profile picture URL: $profilePic');
    } else {
      // Generate avatar as fallback
      final name =
          firstName.isNotEmpty ? firstName : (user.email?.split('@')[0] ?? '');
      await prefs.setString('user_profilePicture',
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random');
    }
  }

  // Basic info from Auth user
  Future<void> _storeBasicUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email ?? '');

    String firstName = '';
    String lastName = '';

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final nameParts = user.displayName!.split(' ');
      firstName = nameParts[0];
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    } else {
      firstName = user.email?.split('@')[0] ?? '';
    }

    await prefs.setString('user_firstName', firstName);
    await prefs.setString('user_lastName', lastName);

    // Profile picture
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      await prefs.setString('user_profilePicture', user.photoURL!);
    } else {
      await prefs.setString('user_profilePicture',
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(firstName)}&background=random');
    }
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 70),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildLoginButton(),
                  const SizedBox(height: 10),
                  _buildErrorMessage(),
                  _buildForgotPasswordButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return RichText(
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
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your email to get started:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              fontSize: 14,
              color: _emailError != null
                  ? Colors.red.shade300
                  : const Color.fromARGB(178, 255, 255, 255),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(9.0)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _emailError != null
                    ? Colors.red
                    : const Color.fromARGB(189, 255, 255, 255),
              ),
              borderRadius: BorderRadius.circular(9.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _emailError != null ? Colors.red : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(9.0),
            ),
            errorText: _emailError,
            errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
            // Removed prefixIcon to restore original layout
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email cannot be empty';
            }
            if (!_isEmailValid(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your password:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: _passwordError != null
                  ? Colors.red.shade300
                  : const Color.fromARGB(178, 255, 255, 255),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(9.0)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _passwordError != null
                    ? Colors.red
                    : const Color.fromARGB(189, 255, 255, 255),
              ),
              borderRadius: BorderRadius.circular(9.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _passwordError != null ? Colors.red : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(9.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: const Color.fromARGB(55, 255, 255, 255),
              ),
              onPressed: _togglePasswordVisibility,
            ),
            errorText: _passwordError,
            errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
            // Removed prefixIcon to restore original layout
          ),
          onChanged: (value) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password cannot be empty';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ScaleTransition(
      scale: _buttonAnimation ?? const AlwaysStoppedAnimation(1.0),
      child: SizedBox(
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
    );
  }

  Widget _buildErrorMessage() {
    if (_generalError == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _generalError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Row(
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _buttonController?.dispose();
    super.dispose();
  }
}
