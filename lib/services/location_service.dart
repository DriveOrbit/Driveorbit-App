import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache the last known position
  Position? _lastKnownPosition;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  // Request permission handler
  Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  // Get current position with error handling
  Future<Position?> getCurrentPosition() async {
    try {
      // First check if location is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions');
      }

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      // Return last known position if available as fallback
      return _lastKnownPosition;
    }
  }

  // Get last known position or fetch a new one
  Future<Position?> getLastKnownPositionOrCurrent() async {
    try {
      // Try to get last known position first as it's faster
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _lastKnownPosition = lastPosition;
        return lastPosition;
      }

      // If not available, get current position
      return getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting position: $e');
      return _lastKnownPosition;
    }
  }
}
