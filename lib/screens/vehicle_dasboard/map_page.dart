import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'package:flutter_screenutil/flutter_screenutil.dart'; // For responsive sizing
import 'dart:async'; // For Timer and StreamSubscription

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _sriLankaCenter =
      LatLng(7.8731, 80.7718); // Sri Lanka Center
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  late DateTime startTime; // Tracks the time when the page is opened
  Timer? durationTimer; // Updates the duration every second
  StreamSubscription<Position>?
      positionSubscription; // Listens to location updates
  double totalMileage = 0.0; // Tracks the total distance traveled
  Position?
      previousPosition; // Stores the previous position for distance calculation

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now(); // Initialize start time
    durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {}); // Update the UI every second
    });
    _getCurrentLocation(); // Fetch initial location and start tracking
  }

  // Function to get current location and start tracking
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    // Request permission
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

    // Get initial position
    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation =
          LatLng(initialPosition.latitude, initialPosition.longitude);
      previousPosition =
          initialPosition; // Set the initial position as previous
    });

    // Start listening to position updates
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy
            .high, // Use 'accuracy' instead of 'desiredAccuracy'
        distanceFilter: 10, // Use 'distanceFilter' inside 'LocationSettings'
      ),
    ).listen((Position position) {
      if (previousPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          previousPosition!.latitude,
          previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        totalMileage += distanceInMeters / 1000; // Convert to kilometers
      }
      previousPosition = position;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  // Function to format duration into HH:mm:ss
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours : $minutes : $seconds";
  }

  // Function to get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    durationTimer?.cancel(); // Cancel the timer
    positionSubscription?.cancel(); // Cancel the position subscription
    _mapController?.dispose(); // Dispose the map controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration currentDuration =
        DateTime.now().difference(startTime); // Calculate current duration

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${getGreeting()}, ',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6D6BF8),
                        fontSize: 18.sp,
                      ),
                    ),
                    TextSpan(
                      text: 'Chandeera!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/chandeera.jpg'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMapView(),
              SizedBox(height: 24.h),
              _buildTimelineSection(currentDuration),
              SizedBox(height: 24.h),
              _buildJobsSection(),
              SizedBox(height: 24.h),
              _buildVehicleInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection(Duration currentDuration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Today's TimeLine",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricItem(
                "${totalMileage.toStringAsFixed(1)} KM", "Current Mileage"),
            _buildMetricItem(
                formatDuration(currentDuration), "Current Duration"),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF6D6BF8),
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Jobs",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildJobRow("License", "No attention needed"),
              Divider(color: Colors.grey[800], height: 24.h),
              _buildJobRow("Insurance", "No attention needed"),
              Divider(color: Colors.grey[800], height: 24.h),
              _buildJobRow("Vehicle Condition", "Attention needed",
                  isAttention: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobRow(String title, String status, {bool isAttention = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
        Text(
          status,
          style: GoogleFonts.poppins(
            color: isAttention ? const Color(0xFF6D6BF8) : Colors.grey,
            fontSize: 14.sp,
            fontWeight: isAttention ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "KY-5590",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Toyota HACE",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "View more info",
              style: GoogleFonts.poppins(
                color: const Color(0xFF6D6BF8),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                target: _sriLankaCenter,
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
