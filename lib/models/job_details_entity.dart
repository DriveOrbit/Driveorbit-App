import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JobDetailsEntity {
  final String historyId; // Matches assignId in Firestore
  final String dateString; // Store original string date
  final String arrivedTimeString; // Store original string time
  final int distance;
  final int duration;
  final String startLocation;
  final String endLocation;
  final String status;
  final String urgency;
  final String customerName;
  final String customerContact;
  final String vehicleType;
  final double estimatedFare;
  final String notes;
  final String driverId;
  final String vehicleId;
  final bool isComplete;

  // Add computed DateTime properties
  DateTime? _date;
  DateTime? _arrivedTime;

  // Getters for DateTime properties with lazy conversion
  DateTime get date {
    if (_date == null) {
      try {
        _date = DateTime.parse(dateString);
      } catch (e) {
        _date = DateTime.now(); // Fallback to current date if parsing fails
      }
    }
    return _date!;
  }

  DateTime get arrivedTime {
    if (_arrivedTime == null) {
      try {
        _arrivedTime = DateTime.parse(arrivedTimeString);
      } catch (e) {
        _arrivedTime =
            DateTime.now(); // Fallback to current time if parsing fails
      }
    }
    return _arrivedTime!;
  }

  // Add formatted string getters for convenience
  String get formattedDate {
    try {
      final dt = date;
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateString;
    }
  }

  String get formattedTime {
    try {
      final dt = arrivedTime;
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return arrivedTimeString;
    }
  }

  JobDetailsEntity({
    required this.historyId,
    required String date,
    required String arrivedTime,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.status,
    required this.urgency,
    required this.customerName,
    required this.customerContact,
    required this.vehicleType,
    required this.estimatedFare,
    required this.notes,
    required this.driverId,
    required this.vehicleId,
    required this.isComplete,
  })  : dateString = date,
        arrivedTimeString = arrivedTime;

  // Used for mock data
  factory JobDetailsEntity.fromJson(Map<String, dynamic> json) {
    return JobDetailsEntity(
      historyId: json['historyId'] ?? '',
      date: json['date'] ?? '',
      arrivedTime: json['arrivedTime'] ?? '',
      distance: json['distance'] is int ? json['distance'] : 0,
      duration: json['duration'] is int ? json['duration'] : 0,
      startLocation: json['startLocation'] ?? '',
      endLocation: json['endLocation'] ?? '',
      status: json['status'] ?? '',
      urgency: json['urgency'] ?? '',
      customerName: json['customerName'] ?? '',
      customerContact: json['customerContact'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      estimatedFare: json['estimatedFare'] is double
          ? json['estimatedFare']
          : (json['estimatedFare'] is int
              ? json['estimatedFare'].toDouble()
              : 0.0),
      notes: json['notes'] ?? '',
      driverId: json['driverId'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      isComplete: json['isComplete'] ?? false,
    );
  }

  // Add a fromFirestore factory method to convert Firestore data
  factory JobDetailsEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return JobDetailsEntity(
      historyId:
          data['assignId'] ?? doc.id, // Use assignId or fallback to document ID
      date: data['date'] ?? '',
      arrivedTime: data['arrivedTime'] ?? '',
      distance: data['distance'] is int
          ? data['distance']
          : (data['distance'] is num ? data['distance'].toInt() : 0),
      duration: data['duration'] is int
          ? data['duration']
          : (data['duration'] is num ? data['duration'].toInt() : 0),
      startLocation: data['startLocation'] ?? '',
      endLocation: data['endLocation'] ?? '',
      status: data['status'] ?? '',
      urgency: data['urgency'] ?? '',
      customerName: data['customerName'] ?? '',
      customerContact: data['customerContact'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      estimatedFare: data['estimatedFare'] is double
          ? data['estimatedFare']
          : (data['estimatedFare'] is num
              ? data['estimatedFare'].toDouble()
              : 0.0),
      notes: data['notes'] ?? '',
      driverId: data['driverId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      isComplete: data['isComplete'] ?? false,
    );
  }

  // Add helper getters for job status
  bool get isPending => !isComplete && (status.toLowerCase() != 'completed');
  bool get isCompleted => isComplete || status.toLowerCase() == 'completed';

  // Add the missing getUrgencyColor method
  Color getUrgencyColor() {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue; // Default color for unknown urgency
    }
  }

  // Add the missing getStatusColor method
  Color getStatusColor() {
    if (isCompleted) {
      return Colors.green;
    }

    switch (status.toLowerCase()) {
      case 'in-progress':
      case 'started':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      case 'scheduled':
        return Colors.purple;
      case 'delayed':
        return Colors.amber;
      default:
        return Colors.grey; // Default color for unknown status
    }
  }
}
