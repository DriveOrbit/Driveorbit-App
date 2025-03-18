import 'package:flutter/material.dart';
import 'auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _userIdController = TextEditingController();
  String? _errorMessage;

  Future<void> _sendUserId() async {
    final userId = _userIdController.text;

    try {
      final response = await sendUserId(userId); // Call the sendUserId function
      final statusCode = response['statusCode'];
      final responseMessage = response['body'];

      if (statusCode == 200) {
        // Navigate to the OTP page with the user ID
        Navigator.pushNamed(context, '/otp', arguments: userId);
      } else {
        // Display error message
        setState(() {
          _errorMessage = responseMessage;
        });
      }
    } catch (e) {
      // Display error message
      setState(() {
        _errorMessage = e.toString();
      });
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
                      text: 'Trouble',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: ' signing in?\nReset your password here!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B59A1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 170),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextField(
                  controller: _userIdController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Enter your company ID',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(139, 238, 236, 236),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(189, 255, 255, 255),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendUserId,
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(186, 255, 255, 255),
                  backgroundColor: const Color.fromARGB(16, 255, 255, 255),
                  side: const BorderSide(
                      color: Color.fromARGB(92, 255, 255, 255), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                child: const Text('Get Password'),
              ),
              const SizedBox(height: 5),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      'Do you know password?',
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
