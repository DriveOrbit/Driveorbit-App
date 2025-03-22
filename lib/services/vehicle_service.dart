import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';

class VehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _hasShownPermissionError = false;

  // Real-time stream of vehicles from Firestore
  Stream<List<VehicleDetailsEntity>> streamVehicles() {
    try {
      debugPrint('🔄 Starting real-time stream of vehicles from Firestore');

      return _db.collection('vehicles').snapshots().map((snapshot) {
        debugPrint(
            '📊 Real-time update: received ${snapshot.docs.length} vehicles');
        return snapshot.docs
            .map((doc) => VehicleDetailsEntity.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Error setting up vehicle stream: $e');
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  // One-time fetch of vehicles
  Future<List<VehicleDetailsEntity>> fetchVehicles() async {
    try {
      debugPrint('🔄 Fetching vehicles from Firestore collection: vehicles');

      QuerySnapshot snapshot = await _db.collection('vehicles').get();

      debugPrint('📊 Fetched ${snapshot.docs.length} vehicles from Firestore');

      if (snapshot.docs.isNotEmpty) {
        debugPrint('🔍 First vehicle data: ${snapshot.docs.first.data()}');
      }

      _hasShownPermissionError = false;

      return snapshot.docs.map((doc) {
        return VehicleDetailsEntity.fromFirestore(doc);
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' && !_hasShownPermissionError) {
        _hasShownPermissionError = true;
        debugPrint('⚠️ Permission denied accessing vehicles collection');
        debugPrint('⚠️ Please update your Firestore rules to include:');
        debugPrint('''
match /vehicles/{vehicleId} {
  allow read: if request.auth != null;
}''');
      }
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'firebase_firestore' && !_hasShownPermissionError) {
        _hasShownPermissionError = true;
        debugPrint('⚠️ Firestore platform exception: ${e.message}');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Error fetching vehicles: $e');
      rethrow;
    }
  }

  // Fetch a single vehicle by ID
  Future<VehicleDetailsEntity?> fetchVehicleById(int vehicleId) async {
    try {
      final QuerySnapshot snapshot = await _db
          .collection('vehicles')
          .where('vehicleId', isEqualTo: vehicleId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No vehicle found with ID: $vehicleId');
        return null;
      }

      return VehicleDetailsEntity.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Error fetching vehicle by ID: $e');
      return null;
    }
  }

  // Fetch vehicles by status (Available, Booked, Not available)
  Future<List<VehicleDetailsEntity>> fetchVehiclesByStatus(
      String status) async {
    try {
      final QuerySnapshot snapshot = await _db
          .collection('vehicles')
          .where('vehicleStatus', isEqualTo: status)
          .get();

      return snapshot.docs.map((doc) {
        return VehicleDetailsEntity.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching vehicles by status: $e');
      return [];
    }
  }

  // Fetch vehicles by type (Car, SUV, Van, Truck, etc.)
  Future<List<VehicleDetailsEntity>> fetchVehiclesByType(String type) async {
    try {
      final QuerySnapshot snapshot = await _db
          .collection('vehicles')
          .where('vehicleType', isEqualTo: type)
          .get();

      return snapshot.docs.map((doc) {
        return VehicleDetailsEntity.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching vehicles by type: $e');
      return [];
    }
  }

  // Stream vehicles by status
  Stream<List<VehicleDetailsEntity>> streamVehiclesByStatus(String status) {
    try {
      return _db
          .collection('vehicles')
          .where('vehicleStatus', isEqualTo: status)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => VehicleDetailsEntity.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Error setting up vehicle status stream: $e');
      return Stream.value([]);
    }
  }

  // Stream vehicles by type
  Stream<List<VehicleDetailsEntity>> streamVehiclesByType(String type) {
    try {
      return _db
          .collection('vehicles')
          .where('vehicleType', isEqualTo: type)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => VehicleDetailsEntity.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Error setting up vehicle type stream: $e');
      return Stream.value([]);
    }
  }
}
