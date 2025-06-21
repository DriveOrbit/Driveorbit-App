import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FuelRecord {
  final String id;
  final String userId;
  final String driverName;
  final String vehicleName;
  final String vehicleId;
  final double amount;
  final double liters;
  final String pricePerLiter;
  final String notes;
  final DateTime timestamp;
  final String date;
  final String time;
  final int currentMileage;
  final DateTime? createdAt;

  FuelRecord({
    required this.id,
    required this.userId,
    required this.driverName,
    required this.vehicleName,
    required this.vehicleId,
    required this.amount,
    required this.liters,
    required this.pricePerLiter,
    required this.notes,
    required this.timestamp,
    required this.date,
    required this.time,
    required this.currentMileage,
    this.createdAt,
  });

  factory FuelRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse timestamp
    DateTime timestamp;
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now(); // Default to current time if invalid
    }

    // Parse createdAt (optional)
    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return FuelRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      driverName: data['driverName'] ?? '',
      vehicleName: data['vehicleName'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      amount:
          (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      liters:
          (data['liters'] is num) ? (data['liters'] as num).toDouble() : 0.0,
      pricePerLiter: data['pricePerLiter'] ?? '0',
      notes: data['notes'] ?? '',
      timestamp: timestamp,
      date: data['date'] ?? DateFormat('yyyy-MM-dd').format(timestamp),
      time: data['time'] ?? DateFormat('hh:mm a').format(timestamp),
      currentMileage: (data['currentMileage'] is num)
          ? (data['currentMileage'] as num).toInt()
          : 0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'driverName': driverName,
      'vehicleName': vehicleName,
      'vehicleId': vehicleId,
      'amount': amount,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'time': time,
      'currentMileage': currentMileage,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Formatted amount with currency symbol
  String get formattedAmount => 'Rs ${amount.toStringAsFixed(2)}';

  // Formatted liters with units
  String get formattedLiters => '${liters.toStringAsFixed(2)} L';

  // Calculate efficiency if mileage data is available
  String get efficiency => 'Rs ${(amount / liters).toStringAsFixed(2)}/L';
}
