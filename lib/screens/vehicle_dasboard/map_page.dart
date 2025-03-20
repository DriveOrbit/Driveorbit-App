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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permissions are permanently denied")),
      );
      return;
    }

    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation =
          LatLng(initialPosition.latitude, initialPosition.longitude);
      previousPosition = initialPosition;
    });

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
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    });
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
                      text: _firstName.isNotEmpty ? '$_firstName!' : 'Driver!',
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
                        ? NetworkImage(_profilePictureUrl) as ImageProvider
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
        child: Stack(
          children: [
            // Map at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.35,
              child: _buildMapView(),
            ),

            // Content area
            Positioned(
              top: 240.h,
              left: 0,
              right: 0,
              bottom: 80.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline header
                      Center(
                        child: Text(
                          "Today's Timeline",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            value: "${totalMileage.toStringAsFixed(1)} KM",
                            label: "Current Mileage",
                          ),
                          _buildStatItem(
                            icon: null,
                            value: formatDuration(currentDuration),
                            label: "Current Duration",
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Jobs Button
                      _buildActionButton("Jobs", onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const JobAssignedPage(),
                          ),
                        );
                      }),
                      SizedBox(height: 20.h),

                      // Vehicle Info
                      _buildVehicleInfoCard(),
                      SizedBox(height: 12.h),

                      // Vehicle Details
                      _buildVehicleDetailsCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Steering Wheel
            Positioned(
              bottom: 20,
              left: (MediaQuery.of(context).size.width - 60.w) / 2,
              child: SizedBox(
                width: 60.w,
                height: 60.w,
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/steering.png',
                    width: 50.w,
                    height: 50.w,
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

  // Reusable stat item widget
  Widget _buildStatItem(
      {IconData? icon, required String value, required String label}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, color: Colors.white, size: 24.sp),
        if (icon != null) SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.sp, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 10.sp, // Reduced font size
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Reusable action button
  Widget _buildActionButton(String text, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.sp, // Reduced font size
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Vehicle info card
  Widget _buildVehicleInfoCard() {
    return Container(
      padding: EdgeInsets.all(12.w), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
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
                  fontSize: 16.sp, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Toyota HIACE",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12.sp, // Reduced font size
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "View more info",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10.sp, // Reduced font size
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vehicle details card
  Widget _buildVehicleDetailsCard() {
    return Container(
      padding: EdgeInsets.all(12.w), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow("License", "No attention needed", Colors.green),
          Divider(color: Colors.grey[800], height: 16.h), // Reduced height
          _buildDetailRow("Insurance", "No attention needed", Colors.green),
          Divider(color: Colors.grey[800], height: 16.h),
          _buildDetailRow(
              "Vehicle Condition", "Attention needed", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12.sp, // Reduced font size
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12.sp, // Reduced font size
                ),
              ),
              if (color == Colors.orange)
                Icon(Icons.info_outline, color: color, size: 14.sp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 1), // Remove left and right margins
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _sriLankaIIT, // Center the map at IIT
                zoom: 13, // Zoom level to show Sri Lanka
              ),
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;

                // Load the dark mode style from the JSON file
                String style = await DefaultAssetBundle.of(context)
                    .loadString('assets/maptheme/dark_theme.json');
                _mapController?.setMapStyle(style);
              },
              markers: {
                if (_currentLocation != null)
                  Marker(
                    markerId: const MarkerId("current_location"),
                    position: _currentLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                  ),
              },
              myLocationEnabled:
                  true, // Enables the red dot for user's location
              myLocationButtonEnabled: true, // Enables the "my location" button
            ),

            // Dark shade at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30, // Adjust the height of the shade
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
                height: 30, // Adjust the height of the shade
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
          ],
        ),
      ),
    );
  }
}
