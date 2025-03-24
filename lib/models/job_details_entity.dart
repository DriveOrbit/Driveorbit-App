import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobDetailsEntity {
  final String historyId;
  final DateTime date;
  final DateTime arrivedTime;
  final int distance;
  final int duration;
  final String startLocation;
  final String endLocation;
  final String status;
  final String urgency;
  final String customerName;
  final String customerContact;
  final String vehicleType;
  final String driverId;
  final String vehicleId;
  final double estimatedFare;
  final String notes;
  final bool isComplete;

  // Add totalDistanceTraveled field from your data
  final double totalDistanceTraveled;

  JobDetailsEntity({
    required this.historyId,
    required this.date,
    required this.arrivedTime,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.status,
    required this.urgency,
    required this.customerName,
    required this.customerContact,
    required this.vehicleType,
    required this.driverId,
    required this.vehicleId,
    required this.estimatedFare,
    required this.notes,
    required this.isComplete,
    this.totalDistanceTraveled = 0.0,
  });

  // Parse Firestore document into JobDetailsEntity with improved error handling
  factory JobDetailsEntity.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract data with fallbacks for missing fields
    final String jobId = doc.id;

    // Get timestamps with fallbacks
    DateTime dateTime = DateTime.now();

    if (data['completedAt'] is Timestamp) {
      dateTime = (data['completedAt'] as Timestamp).toDate();
    } else if (data['endTime'] is Timestamp) {
      dateTime = (data['endTime'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      dateTime = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['startTime'] is Timestamp) {
      dateTime = (data['startTime'] as Timestamp).toDate();
    } else if (data['createdAt'] is Timestamp) {
      dateTime = (data['createdAt'] as Timestamp).toDate();
    }

    // Use same timestamp for arrived time if not available
    DateTime arrivedTime = dateTime;
    if (data['arrivedAt'] is Timestamp) {
      arrivedTime = (data['arrivedAt'] as Timestamp).toDate();
    } else if (data['startTime'] is Timestamp) {
      arrivedTime = (data['startTime'] as Timestamp).toDate();
    }

    // Get distance from different possible fields
    int distance = 0;
    if (data['tripDistance'] is num) {
      distance = (data['tripDistance'] as num).toInt();
    } else if (data['totalDistanceTraveled'] is num) {
      // Convert from double to int for display
      distance = (data['totalDistanceTraveled'] as num).toInt();
    }

    // Store raw double value for total distance traveled
    double totalDistanceTraveled = 0.0;
    if (data['totalDistanceTraveled'] is num) {
      totalDistanceTraveled = (data['totalDistanceTraveled'] as num).toDouble();
    }

    // Get duration
    int duration = 0;
    if (data['tripDurationMinutes'] is num) {
      duration = (data['tripDurationMinutes'] as num).toInt();
    } else if (data['elapsedSeconds'] is num) {
      // Convert seconds to minutes
      duration = ((data['elapsedSeconds'] as num) / 60).round();
    }

    // Get locations
    String startLocation = data['startLocation'] as String? ?? 'Unknown';
    String endLocation = data['endLocation'] as String? ?? 'Unknown';

    // Get status and determine if complete
    String status = data['status'] as String? ?? 'unknown';
    bool isComplete = status.toLowerCase() == 'completed';

    // Get driver ID from appropriate field names
    String driverId = '';
    if (data['driverId'] != null) {
      driverId = data['driverId'].toString();
    } else if (data['driverUid'] != null) {
      driverId = data['driverUid'].toString();
    }

    // Get vehicle ID
    String vehicleId = '';
    if (data['vehicleId'] != null) {
      vehicleId = data['vehicleId'].toString();
    }

    // Get customer info
    String customerName = data['customerName'] as String? ?? 'Unknown Customer';
    String customerContact = data['customerContact'] as String? ?? '';

    // Get vehicle info
    String vehicleType = data['vehicleType'] as String? ?? '';
    // Fallback to vehicleName if vehicleType not available
    if (vehicleType.isEmpty && data['vehicleName'] != null) {
      vehicleType = data['vehicleName'].toString();
    }

    // Get urgency
    String urgency = data['urgency'] as String? ?? 'normal';

    // Get fare
    double estimatedFare = 0.0;
    if (data['estimatedFare'] is num) {
      estimatedFare = (data['estimatedFare'] as num).toDouble();
    }

    // Get notes
    String notes = '';
    if (data['notes'] != null) {
      notes = data['notes'].toString();
    } else if (data['completionNotes'] != null) {
      notes = data['completionNotes'].toString();
    }

    return JobDetailsEntity(
      historyId: jobId,
      date: dateTime,
      arrivedTime: arrivedTime,
      distance: distance,
      duration: duration,
      startLocation: startLocation,
      endLocation: endLocation,
      status: status,
      urgency: urgency,
      customerName: customerName,
      customerContact: customerContact,
      vehicleType: vehicleType,
      driverId: driverId,
      vehicleId: vehicleId,
      estimatedFare: estimatedFare,
      notes: notes,
      isComplete: isComplete,
      totalDistanceTraveled: totalDistanceTraveled,
    );
  }

  // Helper methods
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'started':
      case 'in progress':
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'assigned':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color getUrgencyColor() {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // Format time - add getter for formatted time
  String get formattedTime => DateFormat('hh:mm a').format(arrivedTime);

  // Add getter for date formatting
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  // Add date string getter for legacy code support
  String get dateString => DateFormat('MM/dd/yyyy').format(date);

  // Add arrived time string getter similar to dateString
  String get arrivedTimeString => DateFormat('hh:mm a').format(arrivedTime);

  // Add getter for status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'started':
        return 'In Progress';
      case 'in_progress':
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      case 'assigned':
        return 'Assigned';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  // Get if job is completed (already a property, but this makes API consistent)
  bool get isCompleted => isComplete;

  // Add new getter for pending status
  bool get isPending =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'assigned';

  // Add new getter for in-progress status
  bool get isInProgress =>
      status.toLowerCase() == 'started' ||
      status.toLowerCase() == 'in_progress';
}
