import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:driveorbit_app/screens/job/job_assign.dart'; // Import the real job page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
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

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    _getCurrentLocation();
    _loadUserData();
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

  @override
  void dispose() {
    durationTimer?.cancel();
    positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration currentDuration = DateTime.now().difference(startTime);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isMapFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
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
                      : CircleAvatar(
                          radius: 20.r,
                          backgroundImage: _profilePictureUrl.isNotEmpty
                              ? NetworkImage(_profilePictureUrl)
                                  as ImageProvider
                              : const AssetImage('assets/default_avatar.jpg'),
                          onBackgroundImageError: (_, __) {
                            setState(() {
                              _profilePictureUrl =
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_firstName)}&background=random';
                            });
                          },
                        ),
                ],
              ),
            ),
      body: SafeArea(
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.speed_rounded,
                                value: "${totalMileage.toStringAsFixed(1)} KM",
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
                            SizedBox(width: 12.w), // Space between the stats
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
                      _buildActionButton("View Job Assignments", onPressed: () {
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
                child: SizedBox(
                  width: 80.w, // Increased from 60.w
                  height: 80.w, // Increased from 60.w
                  child: IconButton(
                    icon: Image.asset(
                      'assets/icons/steering.png',
                      width: 70.w, // Increased from 50.w
                      height: 70.w, // Increased from 50.w
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ),
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
              // Navigate to vehicle details page or show dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Vehicle details will be available soon"),
                  duration: Duration(seconds: 2),
                ),
              );
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
                    CircularProgressIndicator(
                      color: const Color(0xFF6D6BF8),
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
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF6D6BF8),
                ),
              ),
            ),

          // Show a loading indicator during transitions
          if (_isTransitioning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF6D6BF8),
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
}
