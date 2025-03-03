import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:slide_countdown/slide_countdown.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  String? _errorMessage;
  String? _apiMessage;
  String? _userId;

  @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   _userId = ModalRoute.of(context)?.settings.arguments as String?;
  //   if (_userId != null) {
  //     _sendUserId();
  //   }
  // }

  // Future<void> _sendUserId() async {
  //   try {
  //     final message = await sendUserId(_userId!);
  //     setState(() {
  //       _apiMessage = message;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _apiMessage = 'Failed to send user ID';
  //     });
  //   }
  // }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;
    Navigator.pushNamed(context, '/dashboard');
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
                      text: 'Enter',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: ' the 6 digits code \nsent to your email',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B59A1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_apiMessage != null)
                Text(
                  _apiMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(172, 172, 172, 172),
                  ),
                ),
              const SizedBox(height: 10),
              OtpTextField(
                numberOfFields: 6,
                borderColor: const Color(0xFF512DA8),
                showFieldAsBox: true,
                fieldWidth: 55.0,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF512DA8),
                    ),
                  ),
                ),
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 244, 244, 244),
                  fontSize: 20,
                ),
                onCodeChanged: (String code) {},
                onSubmit: (String verificationCode) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Verification Code"),
                        content: Text('Code entered is $verificationCode'),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Add your resend OTP logic here
                    },
                    child: const Text(
                      "Didn't receive the OTP?",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SlideCountdownSeparated(
                    duration: Duration(minutes: 2),
                    separatorStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Remove background color
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
