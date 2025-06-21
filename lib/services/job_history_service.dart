import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';

class JobHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current driver's UID
  String? get currentDriverUid => _auth.currentUser?.uid;

  /// Fetch job history for the current driver
  Future<List<JobDetailsEntity>> fetchDriverJobHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy =
        'updatedAt', // Changed default from completedAt to updatedAt
    bool descending = true,
  }) async {
    try {
      if (currentDriverUid == null) {
        throw Exception('No authenticated driver found');
      }

      // Always use the simplified query to prevent index errors
      return await _fetchJobHistorySimplified(
          limit: limit, sortBy: sortBy, descending: descending);
    } catch (e) {
      debugPrint('❌ Error fetching job history: $e');
      // Return empty list instead of throwing to prevent crashes
      return [];
    }
  }

  /// Simplified method that doesn't require complex indexes
  Future<List<JobDetailsEntity>> _fetchJobHistorySimplified({
    required int limit,
    String? sortBy,
    bool descending = true,
  }) async {
    try {
      debugPrint('🔄 Using simplified query method without complex filters');

      // The most basic query - just get jobs for this driver
      // We'll do filtering in memory instead of in the query
      Query query = _firestore
          .collection('jobs')
          .where('driverUid', isEqualTo: currentDriverUid);

      // Only add ordering if we're sorting by a field that exists in most documents
      if (sortBy != null && sortBy != 'completedAt') {
        query = query.orderBy(sortBy, descending: descending);
      }

      // Apply limit (increased to account for filtering)
      query = query.limit(limit * 2);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No job documents found for driver: $currentDriverUid');
        return [];
      }

      // Process and filter results in memory
      final allJobs = snapshot.docs
          .map((doc) => JobDetailsEntity.fromFirestore(doc))
          .where((job) {
        // Include both 'completed' and 'started' statuses
        final status = job.status.toLowerCase();
        return status == 'completed' ||
            status == 'started' ||
            status == 'in_progress';
      }).toList();

      // Sort in memory if needed
      allJobs.sort((a, b) {
        if (sortBy == 'completedAt') {
          return descending
              ? b.date.compareTo(a.date)
              : a.date.compareTo(b.date);
        } else if (sortBy == 'tripDistance') {
          return descending
              ? b.distance.compareTo(a.distance)
              : a.distance.compareTo(b.distance);
        } else if (sortBy == 'tripDurationMinutes') {
          return descending
              ? b.duration.compareTo(a.duration)
              : a.duration.compareTo(b.duration);
        }
        // Default to date sorting
        return descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
      });

      // Apply limit after filtering
      if (allJobs.length > limit) {
        return allJobs.sublist(0, limit);
      }

      debugPrint('Fetched ${allJobs.length} jobs after in-memory filtering');
      return allJobs;
    } catch (e) {
      debugPrint('❌ Error in simplified query: $e');
      return [];
    }
  }

  /// Get index creation requirements message
  static String getIndexRequirementsMessage() {
    return 'Using simplified job history display. Contact your administrator if you need advanced filtering capabilities.';
  }

  /// Fetch job details by ID
  Future<JobDetailsEntity?> fetchJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return JobDetailsEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching job details: $e');
      return null;
    }
  }

  /// Get vehicle details for a job
  Future<Map<String, dynamic>?> fetchVehicleDetailsForJob(
      String vehicleId) async {
    try {
      // Try parsing vehicleId as int if it's stored as a string
      final parsedVehicleId = int.tryParse(vehicleId) ?? vehicleId;

      final snapshot = await _firestore
          .collection('vehicles')
          .where('vehicleId', isEqualTo: parsedVehicleId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
      return null;
    }
  }
}
