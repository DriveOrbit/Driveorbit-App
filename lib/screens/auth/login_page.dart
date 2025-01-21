import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
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
                        color: Color(0xFF54C1D5), // Set color for 'Empower'
                      ),
                    ),
                    TextSpan(
                      text: ' Your Fleet,\nElevate Your Edge',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(
                            0xFF5B59A1), // Set color for 'Your Fleet,\nElevate Your Edge'
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 70),
              const Text(
                'Enter your company ID to get started:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors
                      .white, // Set text color to white for dark background
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity, // Set the width to fill the parent
                height: 40, // Set the desired height
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Company ID',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(178, 255, 255, 255),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color.fromARGB(189, 255, 255, 255),
                      ),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
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
                  color: Colors
                      .white, // Set text color to white for dark background
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity, // Set the width to fill the parent
                height: 40, // Set the desired height
                child: TextField(
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: Color.fromARGB(178, 255, 255, 255),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color.fromARGB(189, 255, 255, 255),
                      ),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
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
              ElevatedButton(
                onPressed: () {
                  // Handle login logic
                },
                child: const Text('Let\'s Drive!'),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(
                    color: const Color.fromARGB(27, 255, 255, 255),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white, // Set text color to white
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
