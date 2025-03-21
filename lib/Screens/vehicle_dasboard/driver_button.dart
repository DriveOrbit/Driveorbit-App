import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicButtonPage extends StatefulWidget {
  const PanicButtonPage({super.key});

  @override
  State<PanicButtonPage> createState() => _PanicButtonPageState();
}

class _PanicButtonPageState extends State<PanicButtonPage>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _emergencyActivated = false;
  double _dragProgress = 0.0;
  final double _dragThreshold =
      0.7; // 70% of the drag area to trigger emergency

  // Emergency contact info - could be fetched from backend in real app
  final String _emergencyNumber = "+94 70 194 2405";

  // Animation controller for pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Completely rewritten emergency call function
  Future<void> _makeEmergencyCall() async {
    // Format phone number by removing any spaces or special characters
    final String formattedNumber =
        _emergencyNumber.replaceAll(RegExp(r'\s+'), '');

    debugPrint('Attempting to call: $formattedNumber');

    try {
      // Use Uri.parse for more reliable URI creation with tel scheme
      final Uri phoneUri = Uri.parse('tel:$formattedNumber');

      // Try to launch URL with external application mode
      final bool result = await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication, // Force external app to handle this
      );

      if (!result) {
        debugPrint(
            'ERROR: Could not launch phone dialer with: $formattedNumber');
        if (mounted) {
          // Show manual dialing dialog as fallback
          _showManualCallDialog(formattedNumber);
        }
      } else {
        debugPrint('Phone dialer launched successfully');
      }
    } catch (e) {
      debugPrint('Exception launching phone dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Show manual dialing dialog as fallback
        _showManualCallDialog(formattedNumber);
      }
    }
  }

  // Rewritten manual call dialog
  void _showManualCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          "Call Emergency Number",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Could not open phone dialer automatically. Please copy the number and dial manually:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      phoneNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.green),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: phoneNumber));
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Number copied to clipboard"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Manual dial button as fallback
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, color: Colors.white),
              label: const Text("DIAL MANUALLY"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onPressed: () async {
                try {
                  final Uri phoneUri = Uri.parse('tel:$phoneNumber');
                  if (await canLaunchUrl(phoneUri)) {
                    Navigator.pop(context);
                    await launchUrl(
                      phoneUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                } catch (e) {
                  debugPrint('Error in manual dial button: $e');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Emergency Assistance',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _emergencyActivated
          ? _buildEmergencyActivatedUI()
          : _buildPanicButtonUI(),
    );
  }

  Widget _buildPanicButtonUI() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Instruction text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              "In case of emergency, drag the button below to the right",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 50.h),
          // The drag area
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(color: Colors.red.shade800, width: 2),
            ),
            child: Stack(
              children: [
                // Drag progress indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: MediaQuery.of(context).size.width * _dragProgress,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                ),
                // Text indicator
                Center(
                  child: Text(
                    "SLIDE TO ACTIVATE EMERGENCY",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                // Draggable handle
                GestureDetector(
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    // Calculate drag percentage based on parent width
                    final parentWidth =
                        MediaQuery.of(context).size.width - 48.w;
                    final newProgress = details.globalPosition.dx / parentWidth;

                    // Ensure progress stays within bounds
                    final boundedProgress = newProgress.clamp(0.0, 1.0);

                    setState(() {
                      _dragProgress = boundedProgress;

                      // Check if we crossed the threshold
                      if (_dragProgress >= _dragThreshold) {
                        _emergencyActivated = true;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_emergencyActivated) {
                      setState(() {
                        _isDragging = false;
                        _dragProgress = 0.0;
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isDragging ? 1.1 : _pulseAnimation.value,
                        child: Container(
                          margin: EdgeInsets.only(
                              left: 5.w +
                                  (MediaQuery.of(context).size.width -
                                          48.w -
                                          70.w) *
                                      _dragProgress),
                          width: 70.w,
                          height: 70.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.7),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emergency,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50.h),
          // Additional info
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.yellow),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "When to use emergency assistance",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "Use this feature only in genuine emergency situations like accidents, vehicle breakdown in unsafe locations, or if you feel your safety is at risk.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActivatedUI() {
    return SafeArea(
      child: Column(
        children: [
          // Status indicators
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(24.w),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "EMERGENCY ACTIVATED",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alert icon and description
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // Animated alert icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 50.sp,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),
                Text(
                  "Help is on the way!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "An administrator has been notified of your emergency and will contact you shortly.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade300,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                // Admin contact info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Emergency Contact",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: Colors.green, size: 22.sp),
                          SizedBox(width: 8.w),
                          Text(
                            _emergencyNumber,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Call button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _makeEmergencyCall, // Connect to the emergency call function
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: const Icon(Icons.call, color: Colors.white),
              label: Text(
                "CALL NOW",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Cancel button
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey.shade900,
                  title: const Text(
                    "Cancel Emergency?",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    "Are you sure you want to cancel the emergency alert? Only do this if your situation is resolved.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("NO",
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.of(context)
                            .pop(); // Return to previous screen
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("YES, CANCEL",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              "Cancel Emergency",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16.sp,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
