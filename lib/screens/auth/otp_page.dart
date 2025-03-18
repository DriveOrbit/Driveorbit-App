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
  String? _email;
  String? _purpose;
  bool _isResendActive = false;
  String _verificationCode = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // We'll get arguments when the widget is fully inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getArguments();
    });
  }

  void _getArguments() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        _email = args['email'] as String?;
        _purpose = args['purpose'] as String?;
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _isResendActive = false;
    });

    Future.delayed(const Duration(minutes: 2), () {
      if (mounted) {
        setState(() {
          _isResendActive = true;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_verificationCode.length != 6) {
      setState(() {
        _errorMessage = "Please enter a valid 6-digit code";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Here you would validate the OTP with your server
      // Simulating API call with a delay
      await Future.delayed(const Duration(seconds: 2));

      // If verification is successful, navigate to reset password page if that's the purpose
      if (_purpose == 'reset_password' && _email != null) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/reset-password',
            arguments: {
              'email': _email,
              'otp': _verificationCode,
            },
          );
        }
      } else {
        // For other purposes like account verification
        if (mounted) {
          Navigator.pushNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to verify OTP. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resendOtp() {
    if (!_isResendActive || _email == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call to resend OTP
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _apiMessage = "OTP sent successfully!";
          _isLoading = false;
        });
      }
      _startResendTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    String headerText = 'Enter the 6 digits code';
    if (_purpose == 'reset_password') {
      headerText = 'Enter the 6 digits code sent to reset your password';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Enter',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text:
                          ' the 6 digits code \nsent to ${_email ?? 'your email'}',
                      style: const TextStyle(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C1D5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _apiMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF54C1D5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              OtpTextField(
                numberOfFields: 6,
                borderColor: const Color(0xFF54C1D5),
                focusedBorderColor: const Color(0xFF5B59A1),
                showFieldAsBox: true,
                fieldWidth: 50.0,
                borderWidth: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF54C1D5),
                    ),
                  ),
                ),
                textStyle: const TextStyle(
                  color: Color(0xFF5B59A1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                onCodeChanged: (String code) {
                  // Clear error message when user starts typing again
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
                onSubmit: (String verificationCode) {
                  setState(() {
                    _verificationCode = verificationCode;
                  });
                  _verifyOtp();
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isResendActive ? _resendOtp : null,
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: _isResendActive
                            ? const Color(0xFF54C1D5)
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B59A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SlideCountdownSeparated(
                      duration: Duration(minutes: 2),
                      separatorStyle: TextStyle(
                        color: Color(0xFF5B59A1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      style: TextStyle(
                        color: Color(0xFF5B59A1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      separatorType: SeparatorType.title,
                      separator: ":",
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF54C1D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
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
                      : const Text(
                          "Verify & Continue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
