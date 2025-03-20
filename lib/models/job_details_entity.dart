import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobDetailsEntity {
  final String historyId;
  final DateTime date;
  final DateTime arrivedTime;
  final double distance;
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
    required this.estimatedFare,
    required this.notes,
  });

  factory JobDetailsEntity.fromJson(Map<String, dynamic> json) {
    return JobDetailsEntity(
      historyId: json['historyId'],
      date: DateTime.parse(json['date']),
      arrivedTime: DateTime.parse(json['arrivedTime']),
      distance: json['distance'].toDouble(),
      duration: json['duration'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      status: json['status'] ?? 'pending',
      urgency: json['urgency'] ?? 'medium',
      customerName: json['customerName'] ?? 'Customer',
      customerContact: json['customerContact'] ?? 'Not provided',
      vehicleType: json['vehicleType'] ?? 'Vehicle',
      estimatedFare: (json['estimatedFare'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
    );
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

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInProgress => status.toLowerCase() == 'in progress';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
