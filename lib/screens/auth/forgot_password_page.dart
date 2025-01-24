import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

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
                        color: Color(0xFF54C1D5), // Set color for 'Trouble'
                      ),
                    ),
                    TextSpan(
                      text: ' signing in?\nReset your password here!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B59A1), // Set color for 'signing in?'
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 170),
              Container(
                width: double.infinity,
                height: 40,
                child: const TextField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
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
                onPressed: () {
                  // Handle get password logic
                },
                child: const Text('Get Password'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(186, 255, 255, 255),
                  backgroundColor: const Color.fromARGB(
                      16, 255, 255, 255), // Button background color
                  side: const BorderSide(
                      color: Color.fromARGB(92, 255, 255, 255),
                      width: 2), // Border color and width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
              const SizedBox(height: 5),
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
