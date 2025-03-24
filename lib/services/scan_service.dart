import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:flutter/foundation.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern - use a true singleton with private constructor
  static final ScanService _instance = ScanService._();
  factory ScanService() => _instance;
  ScanService._();

  // Job ID generation - CRITICAL part for preventing duplicates
  String generateJobId(String vehicleId) {
    return 'job_vehicle_$vehicleId';
  }

  // This is a completely new implementation focused on preventing duplicates
  Future<Map<String, dynamic>> createJob(VehicleDetailsEntity vehicle) async {
    final String vehicleId = vehicle.vehicleId.toString();
    final String jobDocId = generateJobId(vehicleId);

    try {
      // We'll use a transaction to first check if the document exists
      // and only create it if it doesn't
      bool success = false;

      await _firestore.runTransaction((transaction) async {
        // First get the document reference
        final jobDocRef = _firestore.collection('jobs').doc(jobDocId);

        // Check if document exists in the transaction
        final docSnapshot = await transaction.get(jobDocRef);

        if (docSnapshot.exists) {
          // Document already exists, transaction is complete
          // We'll handle this case outside the transaction
          return;
        }

        // Document doesn't exist, create it in the transaction
        final jobData = {
          'jobId': jobDocId,
          'id': jobDocId,
          'vehicleId': vehicleId,
          'vehicleNumber': vehicle.vehicleNumber,
          'vehicleName': vehicle.vehicleModel,
          'status': 'started',
          'createdAt': FieldValue.serverTimestamp(),
          'startTime': FieldValue.serverTimestamp(),
          'plateNumber': vehicle.plateNumber,
          'startDate': _getTodayDate(),
          'startMileage': 0,
          'driverName': 'Unknown Driver',
          'driverUid': '',
          'fuelStatus': 'Full tank',
          'isFuelTankFull': true,
        };

        // Set the document data in the transaction
        transaction.set(jobDocRef, jobData);
        success = true;
      });

      // After transaction completes, check if document exists now
      final docSnapshot =
          await _firestore.collection('jobs').doc(jobDocId).get();

      if (docSnapshot.exists) {
        // Document exists - either it was created in our transaction
        // or it already existed
        return {
          'success':
              success, // If success is true, we created it. Otherwise, it already existed.
          'message': success
              ? 'Job created successfully'
              : 'A job already exists for this vehicle',
          'jobId': jobDocId,
        };
      } else {
        // Unusual case - should not happen, but handle it
        return {
          'success': false,
          'message': 'Failed to create or find job document',
          'jobId': null,
        };
      }
    } catch (e) {
      debugPrint('Error in transaction: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'jobId': null,
      };
    }
  }

  // Get today's date in YYYY-MM-DD format
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Simple method to check if a job exists for the given vehicle
  Future<bool> checkJobExists(String vehicleId) async {
    try {
      final String jobDocId = generateJobId(vehicleId);
      final docSnapshot =
          await _firestore.collection('jobs').doc(jobDocId).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking job existence: $e');
      return false;
    }
  }
}
