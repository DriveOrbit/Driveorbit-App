import 'package:driveorbit_app/Screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/Screens/vehicle_dasboard/vehicle_info.dart';
import 'package:driveorbit_app/models/notification_model.dart';
import 'package:driveorbit_app/screens/profile/driver_profile.dart';
import 'package:driveorbit_app/screens/vehicle_dasboard/driver_button.dart';
import 'package:driveorbit_app/services/notification_service.dart';
import 'package:driveorbit_app/widgets/notification_drawer.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:driveorbit_app/screens/job/job_assign.dart'; // Import the real job page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driveorbit_app/widgets/draggable_notification_circle.dart';
import 'dart:ui';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  static const LatLng _sriLankaIIT = LatLng(6.9016, 79.8602);
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  late DateTime startTime;
  Timer? durationTimer;
  StreamSubscription<Position>? positionSubscription;
  double totalMileage = 0.0;
  Position? previousPosition;

  String _firstName = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;
  bool _isMapFullScreen = false; // New state variable for map fullscreen mode
  bool _isMapLoading = true; // Add this flag to track map loading state
  bool _isTransitioning =
      false; // Add a flag to prevent multiple map operations during transitions

  // Notification related variables
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<NotificationModel> _notifications = [];
  bool _hasUnreadNotifications = false;
  final NotificationService _notificationService = NotificationService();

  // Add animation controllers for notification hint
  AnimationController? _notificationHintController;
  bool _hasShownNotificationTutorial = false;

  // Add fuel warning status
  bool _needsFuelRefill = false;

  // Add job status tracking variables
  bool _isJobInProgress =
      true; // Default to true - assuming driver has an active job
  bool _isJobCompleted = false;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    _getCurrentLocation();
    _loadUserData();
    _loadNotifications();
    _checkFuelStatus(); // Add fuel status check

    // Initialize notification hint animation controller
    _notificationHintController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Check if we've shown the tutorial before
    _checkNotificationTutorial();
  }

  Future<void> _checkNotificationTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownNotificationTutorial =
        prefs.getBool('has_shown_notification_tutorial') ?? false;

    // Show tutorial if it's first time and we have unread notifications
    if (!_hasShownNotificationTutorial && _hasUnreadNotifications) {
      // Wait for the UI to build first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isMapFullScreen) {
          _showNotificationTutorial();
        }
      });
    }
  }

  void _showNotificationTutorial() {
    // Only show in non-fullscreen mode
    if (_isMapFullScreen) return;

    // Start animating the notification hint
    _notificationHintController!.repeat(reverse: true);

    // Show tutorial overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_right, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Swipe right from the left edge to view notifications',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF6D6BF8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          action: SnackBarAction(
            label: 'GOT IT',
            textColor: Colors.white,
            onPressed: () async {
              // Stop the hint animation
              _notificationHintController?.stop();

              // Mark as shown
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_shown_notification_tutorial', true);
              _hasShownNotificationTutorial = true;

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });

    // After 15 seconds, automatically dismiss the tutorial
    Future.delayed(const Duration(seconds: 15), () async {
      if (mounted && _notificationHintController?.isAnimating == true) {
        _notificationHintController?.stop();

        // Mark as shown
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_shown_notification_tutorial', true);
        _hasShownNotificationTutorial = true;
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();

      final cachedFirstName = prefs.getString('user_firstName') ?? '';
      final cachedProfilePic = prefs.getString('user_profilePicture') ?? '';

      if (cachedFirstName.isNotEmpty && mounted) {
        setState(() {
          _firstName = cachedFirstName;
          _profilePictureUrl = cachedProfilePic;
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final freshFirstName = userData['firstName']?.toString() ?? '';
      final freshProfilePic = userData['profilePicture']?.toString() ?? '';

      if (freshFirstName.isNotEmpty && mounted) {
        setState(() {
          _firstName = freshFirstName;
          if (freshProfilePic.isNotEmpty) {
            _profilePictureUrl = freshProfilePic;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    _notifications = await _notificationService.loadSampleNotifications();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = _notificationService.hasUnreadNotifications();
      });
    }
  }

  void _markAsRead(String id) {
    _notificationService.markAsRead(id);
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = _notificationService.hasUnreadNotifications();
      });
    }
  }

  void _markAllAsRead() {
    _notificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled")),
          );
          setState(() => _isMapLoading = false);
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permissions are denied")),
            );
            setState(() => _isMapLoading = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Location permissions are permanently denied")),
          );
          setState(() => _isMapLoading = false);
        }
        return;
      }

      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation =
              LatLng(initialPosition.latitude, initialPosition.longitude);
          previousPosition = initialPosition;
        });
      }

      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (previousPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            previousPosition!.latitude,
            previousPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          totalMileage += distanceInMeters / 1000;
        }
        previousPosition = position;

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);

            // If map controller exists, update camera position
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(_currentLocation!),
              );
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() => _isMapLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting location: $e")),
        );
      }
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours : $minutes : $seconds";
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _toggleFullScreen() async {
    // Prevent multiple rapid toggling
    if (_isTransitioning) return;

    try {
      setState(() {
        _isTransitioning = true;
      });

      // First toggle the fullscreen flag
      setState(() {
        _isMapFullScreen = !_isMapFullScreen;
      });

      // Give the layout time to rebuild before manipulating the map
      await Future.delayed(const Duration(milliseconds: 500));

      // Now safely update the camera if we have what we need
      if (_mapController != null && _currentLocation != null && mounted) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (e) {
      debugPrint("Error toggling fullscreen: $e");
    } finally {
      // Ensure we clear the transitioning flag
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    }
  }

  // Add method to check fuel status
  Future<void> _checkFuelStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isFuelTankFull = prefs.getBool('fuel_tank_full') ?? true;

      if (mounted) {
        setState(() {
          _needsFuelRefill = !isFuelTankFull;
        });
      }
    } catch (e) {
      debugPrint('Error checking fuel status: $e');
    }
  }

  @override
  void dispose() {
    durationTimer?.cancel();
    positionSubscription?.cancel();
    _mapController?.dispose();
    _notificationHintController?.dispose();
    super.dispose();
  }

  // Get count of unread notifications
  int get _unreadNotificationCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  // Show driver options modal with multiple actions and blurred background
  void _showDriverOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            border: Border.all(
              color: const Color(0xFF6D6BF8).withOpacity(0.7),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with transparent background
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[700]!.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Driver Actions",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Add fuel warning banner if needed
              if (_needsFuelRefill)
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.amber.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "Low fuel! Please refill as soon as possible.",
                          style: GoogleFonts.poppins(
                            color: Colors.amber,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Buttons section
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Emergency Assistance
                    _buildDriverActionButton(
                      icon: Icons.emergency,
                      color: Colors.red,
                      title: "Emergency Assistance",
                      description: "Request help in case of emergency",
                      onTap: () {
                        Navigator.pop(context); // Close modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PanicButtonPage(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12.h),

                    // Job Done
                    _buildDriverActionButton(
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      title: "Job Done",
                      description: "Mark current job as completed",
                      onTap: () {
                        Navigator.pop(context); // Close modal
                        _handleJobDone();
                      },
                    ),

                    SizedBox(height: 12.h),

                    // Fuel Filling - Modified with warning icon if needed
                    _buildDriverActionButton(
                      icon: Icons.local_gas_station,
                      color: _needsFuelRefill ? Colors.amber : Colors.blue,
                      title: "Fuel Filling",
                      description: _needsFuelRefill
                          ? "⚠️ Refill fuel as soon as possible"
                          : "Record a fuel filling transaction",
                      onTap: () {
                        Navigator.pop(context); // Close modal
                        _handleFuelFilling();
                      },
                      showWarning: _needsFuelRefill,
                    ),
                  ],
                ),
              ),

              // Cancel button with safe area for bottom padding
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Driver action button with solid black background - Added showWarning parameter
  Widget _buildDriverActionButton({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool showWarning = false, // Add parameter for warning indicator
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.black, // Solid black background
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: showWarning ? Colors.amber : color.withOpacity(0.5),
            width: showWarning ? 2.0 : 1.0, // Thicker border for warning
          ),
          boxShadow: showWarning
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.sp,
                  ),
                ),
                if (showWarning)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.black,
                        size: 10.sp,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: showWarning ? Colors.amber : Colors.grey[400],
                      fontSize: 12.sp,
                      fontWeight:
                          showWarning ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  // Handle job done action with blurred dialog
  void _handleJobDone() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                      0.7), // Increased opacity for better visibility
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.7), // Increased opacity
                    width: 1.5, // Slightly thicker border
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mark Job as Completed",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Are you sure you want to mark the current job as completed?",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    // Fix: Use a Row with proper button constraints
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        SizedBox(
                          width: 100.w, // Fixed width
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        // Confirm button - Fixed width to prevent infinite constraints
                        SizedBox(
                          width: 120.w, // Fixed width
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            onPressed: () {
                              // Update job status
                              setState(() {
                                _isJobCompleted = true;
                                _isJobInProgress = false;
                              });

                              Navigator.pop(context);
                              // Show job completion form instead of just showing a snackbar
                              _showJobCompletionForm();
                            },
                            child: Text(
                              "Confirm",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // New method to show job completion form with enhanced UI
  void _showJobCompletionForm() {
    final mileageController = TextEditingController(
      text: totalMileage.toStringAsFixed(1), // Pre-filled with current mileage
    );
    final notesController = TextEditingController();
    double fuelPercentage = 50.0; // Default value

    // Add validation state variables
    bool isMileageValid = true;
    bool isFuelSelected = true;
    Duration tripDuration = DateTime.now().difference(startTime);
    bool isSubmitting = false; // Add this to track submission state

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.green.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced header with pulsing animation
                  Stack(
                    children: [
                      // Header background
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 20.h,
                          horizontal: 16.w,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade700,
                              Colors.green.shade900,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.r),
                            topRight: Radius.circular(18.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Animated success icon
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 28.sp,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(width: 12.w),

                            // Title with animation
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(20 * (1.0 - value), 0),
                                      child: Text(
                                        "Job Completion Details",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Decorative pill shaped indicators
                      Positioned(
                        top: 12.h,
                        right: 16.w,
                        child: Row(
                          children: List.generate(
                            3,
                            (index) => Container(
                              margin: EdgeInsets.only(left: 4.w),
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.5 - (index * 0.15)),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Form fields with enhanced styling
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section label
                        Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            "COMPLETION DETAILS",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        // Trip Statistics Card - NEW SECTION
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 20.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFF6D6BF8).withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Trip Statistics",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatDetail(
                                      "Distance",
                                      "${totalMileage.toStringAsFixed(1)} KM",
                                      Icons.route,
                                      const Color(0xFF6D6BF8),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: _buildStatDetail(
                                      "Duration",
                                      formatDuration(tripDuration),
                                      Icons.timer,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Current mileage field with enhanced style and validation
                        LabeledTextField(
                          label: "Current Mileage (KM) *",
                          controller: mileageController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.speed,
                          hintText: "Enter current mileage",
                          isValid: isMileageValid,
                          errorText: "Mileage is required",
                          onChanged: (value) {
                            setState(() {
                              isMileageValid = value.trim().isNotEmpty;
                            });
                          },
                        ),
                        SizedBox(height: 20.h),

                        // Enhanced fuel percentage slider with validation label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Fuel Tank Level (Estimate) *",
                              style: GoogleFonts.poppins(
                                color:
                                    isFuelSelected ? Colors.white : Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: _getFuelLevelColor(fuelPercentage)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color:
                                            _getFuelLevelColor(fuelPercentage)
                                                .withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          fuelPercentage > 70
                                              ? Icons.local_gas_station
                                              : fuelPercentage > 30
                                                  ? Icons.battery_4_bar
                                                  : Icons.battery_alert,
                                          color: _getFuelLevelColor(
                                              fuelPercentage),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "${fuelPercentage.toStringAsFixed(0)}%",
                                          style: GoogleFonts.poppins(
                                            color: _getFuelLevelColor(
                                                fuelPercentage),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // ...existing fuel gauge visualization code...

                        // Slider for adjusting fuel level with onChanged to update validation
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                _getFuelLevelColor(fuelPercentage),
                            inactiveTrackColor: Colors.grey.shade800,
                            thumbColor: _getFuelLevelColor(fuelPercentage),
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 12.r,
                            ),
                            overlayColor: _getFuelLevelColor(fuelPercentage)
                                .withOpacity(0.2),
                            trackHeight: 4.h,
                          ),
                          child: Slider(
                            value: fuelPercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                fuelPercentage = value;
                                isFuelSelected =
                                    true; // Mark as selected when user moves slider
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Additional notes with enhanced styling (optional field)
                        LabeledTextField(
                          label: "Additional Notes (Optional)",
                          controller: notesController,
                          keyboardType: TextInputType.multiline,
                          prefixIcon: Icons.note_alt_outlined,
                          hintText:
                              "Any additional details about the job completion...",
                          maxLines: 3,
                          isValid: true, // Always valid as it's optional
                        ),

                        SizedBox(height: 24.h),

                        // Divider before action buttons
                        Divider(color: Colors.grey.shade700),
                        SizedBox(height: 16.h),

                        // Action buttons with enhanced styling and validation
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade500),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  "CANCEL",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade300,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        // Validate form fields
                                        setState(() {
                                          isMileageValid = mileageController
                                              .text
                                              .trim()
                                              .isNotEmpty;
                                          // Consider the slider value selected if user moved it
                                          isFuelSelected = true;
                                        });

                                        // Only proceed if all required fields are valid
                                        if (isMileageValid && isFuelSelected) {
                                          setState(() {
                                            isSubmitting =
                                                true; // Disable button while submitting
                                          });

                                          // Save job completion data
                                          try {
                                            // Get values from form
                                            final endMileage = double.tryParse(
                                                    mileageController.text
                                                        .trim()) ??
                                                0.0;
                                            final notes =
                                                notesController.text.trim();
                                            final fuelLevel = fuelPercentage;

                                            // Store completion data in Firestore
                                            await _completeJobInFirestore(
                                                endMileage: endMileage,
                                                notes: notes,
                                                fuelLevel: fuelLevel);

                                            // Reset job status for next job
                                            this.setState(() {
                                              _isJobInProgress = false;
                                              _isJobCompleted = false;
                                            });

                                            // Close the completion form first
                                            Navigator.pop(context);

                                            // Show success dialog before redirecting
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) =>
                                                  WillPopScope(
                                                onWillPop: () async => false,
                                                child: Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  elevation: 0,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.all(20.w),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade900,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.r),
                                                      border: Border.all(
                                                          color: Colors.green,
                                                          width: 2),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Success animation
                                                        TweenAnimationBuilder<
                                                            double>(
                                                          tween: Tween<double>(
                                                              begin: 0.0,
                                                              end: 1.0),
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      800),
                                                          curve:
                                                              Curves.elasticOut,
                                                          builder: (context,
                                                              value, child) {
                                                            return Transform
                                                                .scale(
                                                              scale: value,
                                                              child: Container(
                                                                width: 80.w,
                                                                height: 80.w,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .green
                                                                      .withOpacity(
                                                                          0.2),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .check_circle,
                                                                    color: Colors
                                                                        .green,
                                                                    size: 60.sp,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        SizedBox(height: 16.h),
                                                        Text(
                                                          "Job Completed!",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20.sp,
                                                          ),
                                                        ),
                                                        SizedBox(height: 8.h),
                                                        Text(
                                                          "Thank you for completing this job successfully.",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors
                                                                .grey.shade300,
                                                            fontSize: 14.sp,
                                                          ),
                                                        ),
                                                        SizedBox(height: 24.h),

                                                        // Auto-redirecting in 2 seconds
                                                        TweenAnimationBuilder<
                                                            double>(
                                                          tween: Tween<double>(
                                                              begin: 0.0,
                                                              end: 1.0),
                                                          duration:
                                                              const Duration(
                                                                  seconds: 2),
                                                          onEnd: () {
                                                            // Navigate to dashboard after completion
                                                            Navigator.of(
                                                                    context)
                                                                .pushAndRemoveUntil(
                                                              PageRouteBuilder(
                                                                pageBuilder: (context,
                                                                        animation,
                                                                        secondaryAnimation) =>
                                                                    const DashboardDriverPage(),
                                                                transitionsBuilder:
                                                                    (context,
                                                                        animation,
                                                                        secondaryAnimation,
                                                                        child) {
                                                                  return FadeTransition(
                                                                    opacity:
                                                                        animation,
                                                                    child:
                                                                        child,
                                                                  );
                                                                },
                                                                transitionDuration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            500),
                                                              ),
                                                              (route) => false,
                                                            );
                                                          },
                                                          builder: (context,
                                                              value, child) {
                                                            return Column(
                                                              children: [
                                                                // Progress indicator
                                                                LinearProgressIndicator(
                                                                  value: value,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .grey
                                                                          .shade800,
                                                                  valueColor: const AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .green),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        8.h),
                                                                Text(
                                                                  "Redirecting to dashboard...",
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade400,
                                                                    fontSize:
                                                                        12.sp,
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            // Handle any errors during job completion
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Error completing job: $e",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                backgroundColor:
                                                    Colors.red.shade700,
                                                duration:
                                                    const Duration(seconds: 4),
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                isSubmitting = false;
                                              });
                                            }
                                          }
                                        } else {
                                          // Show validation error effect (fields are already marked)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "Please fill all required fields marked with *",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              backgroundColor:
                                                  Colors.red.shade700,
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.w,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            "COMPLETE JOB",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
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
          ),
        ),
      ),
    );
  }

  // Add a method to complete the job in Firestore
  Future<void> _completeJobInFirestore({
    required double endMileage,
    required String notes,
    required double fuelLevel,
  }) async {
    try {
      // Get current job ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentJobId = prefs.getString('current_job_id');

      // If no job ID is found, we can't update the record
      if (currentJobId == null || currentJobId.isEmpty) {
        debugPrint(
            'No current job ID found in SharedPreferences, unable to complete job');
        throw Exception('No active job found');
      }

      // Calculate trip statistics
      final startMileage = prefs.getInt('current_mileage') ?? 0;
      final tripDistance = endMileage - startMileage;
      final endTime = DateTime.now();
      final tripDuration = endTime.difference(startTime);

      // Format the duration in minutes for storage
      final tripDurationMinutes = tripDuration.inMinutes;

      // Create the completion data
      final completionData = {
        'endMileage': endMileage,
        'endTime': Timestamp.fromDate(endTime),
        'endFuelLevel': fuelLevel, // Store as percentage (0-100)
        'endFuelStatus': _getFuelStatusText(fuelLevel),
        'completionNotes': notes,
        'status': 'completed',
        'tripDistance':
            tripDistance > 0 ? tripDistance : 0, // Ensure positive value
        'tripDurationMinutes': tripDurationMinutes,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the existing job document
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(currentJobId)
          .update(completionData);

      debugPrint('Job completed successfully in Firestore');

      // Clear the current job ID from SharedPreferences
      await prefs.remove('current_job_id');
    } catch (e) {
      debugPrint('Error completing job: $e');
      rethrow; // Re-throw to handle in the calling method
    }
  }

  // Helper method to convert fuel level percentage to text status
  String _getFuelStatusText(double fuelLevel) {
    if (fuelLevel >= 75) {
      return 'Full tank';
    } else if (fuelLevel >= 50) {
      return 'Three-quarter tank';
    } else if (fuelLevel >= 25) {
      return 'Half tank';
    } else if (fuelLevel >= 10) {
      return 'Quarter tank';
    } else {
      return 'Refuel needed';
    }
  }

  // Helper widget for trip statistics items
  Widget _buildStatDetail(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper class for consistent text field styling - updated with validation
  Widget LabeledTextField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isValid = true,
    String errorText = "",
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isValid ? Colors.white : Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.sp,
            ),
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade800.withOpacity(0.7),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: isValid ? Colors.grey.shade400 : Colors.red.shade300,
                size: 18.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isValid ? Colors.grey.shade700 : Colors.red,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isValid ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              // Show error message if field is invalid
              errorText: !isValid ? errorText : null,
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Method to get fuel level color based on percentage
  Color _getFuelLevelColor(double percentage) {
    if (percentage > 70) {
      return Colors.green;
    } else if (percentage > 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Handle fuel filling action with blurred dialog - modified to update fuel status and save records
  void _handleFuelFilling() {
    // Show fuel filling form dialog with blur effect
    final amountController = TextEditingController();
    final litersController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;
    bool isFormValid = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade700,
                          Colors.amber.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_gas_station,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "Fuel Filling Details",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form fields
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show warning message if refill needed
                        if (_needsFuelRefill)
                          Container(
                            margin: EdgeInsets.only(bottom: 20.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    "Completing this form will update your fuel status",
                                    style: GoogleFonts.poppins(
                                      color: Colors.amber,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Amount field - With validation
                        Text(
                          "Amount (Rs) *",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {
                              isFormValid = _validateFuelForm(
                                  amountController.text, litersController.text);
                            });
                          },
                          decoration: InputDecoration(
                            fillColor: Colors.black.withOpacity(0.2),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                              ),
                            ),
                            hintText: "Enter amount paid",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Liters field - With validation
                        Text(
                          "Liters *",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: litersController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {
                              isFormValid = _validateFuelForm(
                                  amountController.text, litersController.text);
                            });
                          },
                          decoration: InputDecoration(
                            fillColor: Colors.black.withOpacity(0.2),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                              ),
                            ),
                            hintText: "Enter liters filled",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.water_drop_outlined,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Notes field (optional)
                        Text(
                          "Notes (Optional)",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: InputDecoration(
                            fillColor: Colors.black.withOpacity(0.2),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                              ),
                            ),
                            hintText: "Any additional notes...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  "CANCEL",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade300,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (!isFormValid || isSubmitting)
                                    ? null
                                    : () async {
                                        setState(() {
                                          isSubmitting = true;
                                        });

                                        // Get values from controllers
                                        final amountText =
                                            amountController.text.trim();
                                        final litersText =
                                            litersController.text.trim();
                                        final notesText =
                                            notesController.text.trim();

                                        // Parse values
                                        double amount =
                                            double.tryParse(amountText) ?? 0;
                                        double liters =
                                            double.tryParse(litersText) ?? 0;

                                        // Create fuel record
                                        await _storeFuelFillingRecord(
                                            amount: amount,
                                            liters: liters,
                                            notes: notesText);

                                        // Update the fuel tank status in SharedPreferences
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setBool(
                                            'fuel_tank_full', true);

                                        // Update the UI state
                                        if (mounted) {
                                          this.setState(() {
                                            _needsFuelRefill = false;
                                          });
                                        }

                                        // Show success message
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: Text(
                                                    'Fuel filling details saved successfully!',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                Colors.green.shade700,
                                            duration:
                                                const Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isFormValid ? Colors.amber : Colors.grey,
                                  disabledBackgroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.w,
                                        ),
                                      )
                                    : Text(
                                        "SUBMIT",
                                        style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
          ),
        ),
      ),
    );
  }

  // Validate the fuel filling form
  bool _validateFuelForm(String amountText, String litersText) {
    bool isAmountValid = false;
    bool isLitersValid = false;

    // Validate amount
    if (amountText.isNotEmpty) {
      double? amount = double.tryParse(amountText);
      isAmountValid = amount != null && amount > 0;
    }

    // Validate liters
    if (litersText.isNotEmpty) {
      double? liters = double.tryParse(litersText);
      isLitersValid = liters != null && liters > 0;
    }

    return isAmountValid && isLitersValid;
  }

  // Store fuel filling record in the jobs collection instead of creating a new collection
  Future<void> _storeFuelFillingRecord({
    required double amount,
    required double liters,
    String notes = "",
  }) async {
    try {
      // Get current user info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get current job ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentJobId = prefs.getString('current_job_id');

      // If no job ID is found, we can't update the record
      if (currentJobId == null || currentJobId.isEmpty) {
        debugPrint('No current job ID found in SharedPreferences');
        return;
      }

      // Create record data
      final now = DateTime.now();
      final fuelData = {
        'fuelRefills': FieldValue.arrayUnion([
          {
            'amount': amount,
            'liters': liters,
            'pricePerLiter':
                liters > 0 ? (amount / liters).toStringAsFixed(2) : '0',
            'notes': notes,
            'timestamp': Timestamp.fromDate(now),
            'date': now.toString().split(' ')[0],
            'time': DateFormat('hh:mm a').format(now),
          }
        ]),
        'lastFuelRefill': {
          'amount': amount,
          'liters': liters,
          'timestamp': Timestamp.fromDate(now),
          'notes': notes,
        },
        'isFuelTankFull': true,
        'fuelStatus': 'Full tank',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the existing job document
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(currentJobId)
          .update(fuelData);

      debugPrint('Fuel record stored successfully in job document');
    } catch (e) {
      debugPrint('Error storing fuel record: $e');
      rethrow; // Re-throw to handle in the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    Duration currentDuration = DateTime.now().difference(startTime);
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop, // Add back button handling
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        // Special handling for map page - conditionally enable edge swipe
        drawerEnableOpenDragGesture: !_isMapFullScreen,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.5,
        drawer: NotificationDrawer(
          notifications: _notifications,
          onMarkAsRead: _markAsRead,
          onMarkAllAsRead: _markAllAsRead,
          hasUnreadNotifications: _hasUnreadNotifications,
        ),
        appBar: _isMapFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DriverProfilePage()));
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${getGreeting()} ',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6D6BF8),
                                  fontSize: 22.sp,
                                ),
                              ),
                              TextSpan(
                                text: _firstName.isNotEmpty
                                    ? '$_firstName!'
                                    : 'Driver!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 9.w),
                    _isLoading
                        ? SizedBox(
                            width: 40.w,
                            height: 40.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const DriverProfilePage()));
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20.r,
                                  backgroundImage: _profilePictureUrl.isNotEmpty
                                      ? NetworkImage(_profilePictureUrl)
                                          as ImageProvider
                                      : const AssetImage(
                                          'assets/default_avatar.jpg'),
                                  onBackgroundImageError: (_, __) {
                                    setState(() {
                                      _profilePictureUrl =
                                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_firstName)}&background=random';
                                    });
                                  },
                                ),
                                // Notification indicator on avatar
                                if (_hasUnreadNotifications)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),

        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Map section - expanded to full screen if in fullscreen mode
                  _isMapFullScreen
                      ? Expanded(
                          child: _buildMapView(),
                        )
                      : SizedBox(
                          height: screenHeight * 0.35,
                          width: double.infinity,
                          child: _buildMapView(),
                        ),

                  // Content area - only shown if not in fullscreen mode
                  if (!_isMapFullScreen)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            // Timeline header
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: Text(
                                "Today's Timeline",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Stats Row - Enhanced design
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 20.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      icon: Icons.speed_rounded,
                                      value:
                                          "${totalMileage.toStringAsFixed(1)} KM",
                                      label: "Current Mileage",
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6D6BF8),
                                          Color(0xFF5856D6)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: 12.w), // Space between the stats
                                  Expanded(
                                    child: _buildStatItem(
                                      icon: Icons.timer_outlined,
                                      value: formatDuration(currentDuration),
                                      label: "Current Duration",
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF2E7D32)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Jobs Button - Moved outside of ScrollView to make it fixed
                            _buildActionButton("View Job Assignments",
                                onPressed: () {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (_) => const JobAssignedPage(),
                                ),
                              )
                                  .then((_) {
                                // Optional: refresh data when returning from job assignments page
                                if (mounted) {
                                  setState(() {
                                    // Reset any state if needed after returning
                                  });
                                }
                              });
                            }),
                            SizedBox(height: 20.h),

                            // Content scrollable area
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Vehicle Info
                                    _buildVehicleInfoCard(),
                                    // Add some bottom padding for scrolling
                                    SizedBox(height: 16.h),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Steering Wheel - only shown if not in fullscreen mode
                  if (!_isMapFullScreen)
                    Container(
                      height: 100.h, // Increased from 80.h
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Steering wheel button
                          SizedBox(
                            width: 80.w, // Increased from 60.w
                            height: 80.w, // Increased from 60.w
                            child: IconButton(
                              icon: Image.asset(
                                'assets/icons/steering.png',
                                width: 70.w, // Increased from 50.w
                                height: 70.w, // Increased from 50.w
                                color: Colors.white,
                              ),
                              onPressed:
                                  _showDriverOptions, // Use the new method to show options
                            ),
                          ),

                          // Fuel warning indicator
                          if (_needsFuelRefill)
                            Positioned(
                              top: 15.h,
                              right: 15.w,
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.black,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Replace the old notification circle with the new animated one
            if (_hasUnreadNotifications && !_isMapFullScreen)
              DraggableNotificationCircle(
                notificationCount: _unreadNotificationCount,
                onDragComplete: () => _scaffoldKey.currentState?.openDrawer(),
                showIndicator: true,
              ),
          ],
        ),
      ),
    );
  }

  // Reusable stat item widget - completely redesigned
  Widget _buildStatItem({
    IconData? icon,
    required String value,
    required String label,
    LinearGradient? gradient,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Small indicator to show active tracking
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                "TRACKING",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable action button - enhanced style
  Widget _buildActionButton(String text, {VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Show loading indicator when button is pressed
          if (onPressed != null) {
            setState(() {
              _isLoading = true; // Set loading state
            });

            try {
              await Future.delayed(const Duration(
                  milliseconds: 100)); // Brief delay for UI feedback
              onPressed(); // Execute the callback
            } finally {
              // In case we come back from navigation, ensure loading is reset
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(15), // Increased radius
        splashColor: const Color(0xFF6D6BF8).withOpacity(0.4),
        highlightColor: Colors.grey[800],
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.grey[850], // Slightly lighter background
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: const Color(0xFF6D6BF8), width: 2), // Thicker border
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D6BF8).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline,
                color: const Color(0xFF6D6BF8),
                size: 22.sp, // Slightly larger icon
              ),
              SizedBox(width: 12.w), // More spacing
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, // Better letter spacing
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vehicle info card - enhanced layout
  Widget _buildVehicleInfoCard() {
    return Container(
      padding: EdgeInsets.all(18.w), // More padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Gradient background
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[850]!,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "KY-5590",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20.sp, // Larger font size
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h), // Space between elements
              Text(
                "Toyota HIACE",
                style: GoogleFonts.poppins(
                  color: Colors.grey[400], // Lighter grey for better contrast
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) => const VehicleInfoPage(),
                ),
              )
                  .then((_) {
                // Optional: refresh data when returning from job assignments page
                if (mounted) {
                  setState(() {
                    // Reset any state if needed after returning
                  });
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6D6BF8), width: 1),
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[850], // Slightly lighter background
              ),
              child: Row(
                children: [
                  Text(
                    "View more info",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500, // Slightly bolder
                    ),
                  ),
                  SizedBox(width: 4.w),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF6D6BF8),
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        children: [
          // Show a loading indicator while map is initializing
          if (_isMapLoading)
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF6D6BF8),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Loading map...",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Google Map with improved error handling
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: GoogleMap(
              key: ValueKey<bool>(
                  _isMapFullScreen), // Recreate map on fullscreen toggle
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? _sriLankaIIT,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) async {
                try {
                  _mapController = controller;

                  // Load the dark mode style from the JSON file
                  try {
                    String style = await DefaultAssetBundle.of(context)
                        .loadString('assets/maptheme/dark_theme.json');
                    await _mapController?.setMapStyle(style);
                  } catch (e) {
                    debugPrint("Error loading map style: $e");
                    // Continue without custom style if it fails to load
                  }

                  // Mark map as loaded
                  if (mounted) {
                    setState(() {
                      _isMapLoading = false;
                    });
                  }

                  // If we have a location, move camera to it
                  if (_currentLocation != null && mounted) {
                    await Future.delayed(const Duration(milliseconds: 300));
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                    );
                  }
                } catch (e) {
                  debugPrint("Error setting up map: $e");
                  if (mounted) {
                    setState(() => _isMapLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error initializing map: $e")),
                    );
                  }
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Hide default location button
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
            ),
          ),

          // Overlay for error cases but show map is still loading
          if (_isMapLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6D6BF8),
                ),
              ),
            ),

          // Show a loading indicator during transitions
          if (_isTransitioning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6D6BF8),
                ),
              ),
            ),

          // Custom location button
          Positioned(
            right: 16,
            bottom: _isMapFullScreen
                ? 70
                : 16, // Position higher when in fullscreen mode to avoid back button
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6D6BF8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location,
                  color: Color(0xFF6D6BF8),
                ),
                onPressed: () {
                  if (_mapController != null &&
                      _currentLocation != null &&
                      !_isTransitioning) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                    );
                  }
                },
                tooltip: 'My Location',
              ),
            ),
          ),

          // Expand/Contract button - update to use our new toggle method
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6D6BF8),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _isMapFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _isTransitioning ? null : _toggleFullScreen,
                tooltip: _isMapFullScreen ? 'Exit fullscreen' : 'Fullscreen',
              ),
            ),
          ),

          // Dark shade at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(1.0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Dark shade at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(1.0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Back button when in fullscreen mode
          if (_isMapFullScreen)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF6D6BF8),
                      width: 1,
                    ),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Back to Dashboard",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _isTransitioning ? null : _toggleFullScreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Handle back button press to prevent accidental navigation
  Future<bool> _onWillPop() async {
    if (!_isJobCompleted && _isJobInProgress) {
      // If job is still in progress, show warning dialog
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => _buildJobIncompleteDialog(),
      );
      return shouldPop ?? false;
    } else if (_isJobCompleted && !_isJobInProgress) {
      // If job is completed but form not shown yet, show completion form
      _showJobCompletionForm();
      return false;
    }

    // Default case - allow navigation
    return true;
  }

  // Dialog to show when trying to leave with job in progress
  Widget _buildJobIncompleteDialog() {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 28.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Job In Progress",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You still have an active job that needs to be completed.",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Please complete your current job before leaving this screen.",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "To complete a job, click on the steering wheel icon and select 'Job Done'.",
                    style: GoogleFonts.poppins(
                      color: Colors.amber,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false), // Don't allow going back
          child: Text(
            "STAY ON THIS PAGE",
            style: GoogleFonts.poppins(
              color: const Color(0xFF6D6BF8),
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onPressed: () => Navigator.of(context)
              .pop(true), // Force navigation (emergency override)
          child: Text(
            "LEAVE ANYWAY",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
