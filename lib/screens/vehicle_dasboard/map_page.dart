import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718); // Sri Lanka Center
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
        SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permissions are denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permissions are permanently denied")),
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _sriLankaCenter,
          zoom: 13, // Zoom level to show Sri Lanka
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId("current_location"),
            position: _sriLankaCenter,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        },
        myLocationEnabled: true, // Enables the blue dot for user's location
        myLocationButtonEnabled: true, // Enables the "my location" button
      ),
    );
  }
}
