import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicButtonPage extends StatefulWidget {
  const PanicButtonPage({Key? key}) : super(key: key);

  @override
  State<PanicButtonPage> createState() => _PanicButtonPageState();
}

class _PanicButtonPageState extends State<PanicButtonPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isEmergencyActivated = false;
  bool _showConfirmation = false;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startEmergencyProcess() {
    setState(() {
      _showConfirmation = true;
    });

    // Start the countdown
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown > 0) {
          _startCountdown();
        } else {
          // Time's up, activate emergency
          _activateEmergency();
        }
      }
    });
  }

  void _cancelEmergency() {
    setState(() {
      _showConfirmation = false;
      _countdown = 5;
    });
  }

  void _activateEmergency() {
    setState(() {
      _isEmergencyActivated = true;
      _showConfirmation = false;
    });

    // Simulate calling emergency services
    _callEmergencyServices();
  }

  Future<void> _callEmergencyServices() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '1990');
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Emergency Assistance',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need Help?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Use this button in case of emergency to alert our support team and authorities.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
              ),
              Expanded(
                child: Center(
                  child: _isEmergencyActivated
                      ? _buildEmergencyActivated()
                      : _buildEmergencyButton(),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildContactItem('Police Emergency', '119'),
                    SizedBox(height: 8.h),
                    _buildContactItem('Ambulance', '1990'),
                    SizedBox(height: 8.h),
                    _buildContactItem('DriveOrbit Support', '0112345678'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing circle
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2 * _animationController.value),
              ),
            );
          },
        ),

        // Middle circle
        Container(
          width: 180.w,
          height: 180.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.3),
          ),
        ),

        // Inner circle - the actual button
        GestureDetector(
          onTap: _startEmergencyProcess,
          child: Container(
            width: 150.w,
            height: 150.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 50.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'SOS',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Confirmation overlay
        if (_showConfirmation)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Emergency will activate in',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _cancelEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyActivated() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 60.sp,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Emergency Activated',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Help is on the way!',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEmergencyActivated = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
          child: Text(
            'RESET',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(String name, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.phone,
              color: Colors.blue,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () async {
            final Uri phoneUri = Uri(scheme: 'tel', path: number);
            try {
              await launchUrl(phoneUri);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch phone: $e')),
                );
              }
            }
          },
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
