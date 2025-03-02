import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'package:flutter_screenutil/flutter_screenutil.dart'; // For responsive sizing

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Function to get current location
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

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    });
  }

  // Function to get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMapView(),
            ],
          ),
        ),
      ),
 
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 30, left: 16, right: 16), // Adjust the margin
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _sriLankaCenter,
                zoom: 13, // Zoom level to show Sri Lanka
              ),
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;

                // Load the dark mode style from the JSON file
    String style = await DefaultAssetBundle.of(context).loadString('assets/maptheme/dark_theme.json');
    _mapController?.setMapStyle(style);
              },
              markers: {
                if (_currentLocation != null)
                  Marker(
                    markerId: const MarkerId("current_location"),
                    position: _currentLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
              },
              myLocationEnabled:true, // Enables the red dot for user's location
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