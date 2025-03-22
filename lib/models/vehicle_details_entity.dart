import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VehicleDetailsEntity {
  final int vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleImage;
  final String vehicleStatus;

  // New fields from Firestore
  final String condition;
  final double fuelConsumption;
  final String fuelType;
  final String gearSystem;
  final bool hasEmergencyKit;
  final bool hasSpareTools;
  final String plateNumber;
  final String qrCodeURL;
  final int recommendedDistance;
  final String warnings;
  final bool isFavorite;

  VehicleDetailsEntity({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleImage,
    required this.vehicleStatus,
    this.condition = '',
    this.fuelConsumption = 0.0,
    this.fuelType = '',
    this.gearSystem = '',
    this.hasEmergencyKit = false,
    this.hasSpareTools = false,
    this.plateNumber = '',
    this.qrCodeURL = '',
    this.recommendedDistance = 0,
    this.warnings = '',
    this.isFavorite = false,
  });

  // Updated Firestore conversion to support both DocumentSnapshot and Map<String, dynamic>
  factory VehicleDetailsEntity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Debug print for data inspection
    debugPrint(
        'Mapping Firestore doc ID: ${doc.id} with fields: ${data.keys.join(', ')}');

    return VehicleDetailsEntity.fromMap(data);
  }

  // New method to create from a Map (useful for both Firestore and direct mapping)
  factory VehicleDetailsEntity.fromMap(Map<String, dynamic> data) {
    return VehicleDetailsEntity(
      vehicleId: data['vehicleId'] ?? 0,
      vehicleNumber: data['vehicleNumber'] ?? data['plateNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehicleImage: data['vehicleImage'] ?? 'assets/car.png',
      vehicleStatus: data['vehicleStatus'] ?? 'Not available',
      condition: data['condition'] ?? '',
      fuelConsumption: _parseDoubleValue(data['fuelConsumption']),
      fuelType: data['fuelType'] ?? '',
      gearSystem: data['gearSystem'] ?? '',
      hasEmergencyKit: data['hasEmergencyKit'] ?? false,
      hasSpareTools: data['hasSpareTools'] ?? false,
      plateNumber: data['plateNumber'] ?? data['vehicleNumber'] ?? '',
      qrCodeURL: data['qrCodeURL'] ?? '',
      recommendedDistance: data['recommendedDistance'] ?? 0,
      warnings: data['warnings'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  // Helper method to handle numeric values that might be stored in different formats
  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Update the fromJson factory to properly handle all fields
  factory VehicleDetailsEntity.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsEntity(
      vehicleId: json['vehicleId'] ?? 0,
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleImage: json['vehicleImage'] ?? 'assets/car.png',
      vehicleStatus: json['vehicleStatus'] ?? 'Not available',
      // Include all fields with default values
      condition: json['condition'] ?? 'Unknown',
      fuelConsumption: (json['fuelConsumption'] is num)
          ? (json['fuelConsumption'] as num).toDouble()
          : 0.0,
      fuelType: json['fuelType'] ?? 'Unknown',
      gearSystem: json['gearSystem'] ?? 'Unknown',
      hasEmergencyKit: json['hasEmergencyKit'] ?? false,
      hasSpareTools: json['hasSpareTools'] ?? false,
      plateNumber: json['plateNumber'] ?? json['vehicleNumber'] ?? '',
      qrCodeURL: json['qrCodeURL'] ?? '',
      recommendedDistance: json['recommendedDistance'] ?? 0,
      warnings: json['warnings'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Add a copyWith method to create a new instance with updated values
  VehicleDetailsEntity copyWith({
    int? vehicleId,
    String? vehicleNumber,
    String? vehicleType,
    String? vehicleModel,
    String? vehicleImage,
    String? vehicleStatus,
    String? condition,
    double? fuelConsumption,
    String? fuelType,
    String? gearSystem,
    bool? hasEmergencyKit,
    bool? hasSpareTools,
    String? plateNumber,
    String? qrCodeURL,
    int? recommendedDistance,
    String? warnings,
    bool? isFavorite,
  }) {
    return VehicleDetailsEntity(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      vehicleStatus: vehicleStatus ?? this.vehicleStatus,
      condition: condition ?? this.condition,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelType: fuelType ?? this.fuelType,
      gearSystem: gearSystem ?? this.gearSystem,
      hasEmergencyKit: hasEmergencyKit ?? this.hasEmergencyKit,
      hasSpareTools: hasSpareTools ?? this.hasSpareTools,
      plateNumber: plateNumber ?? this.plateNumber,
      qrCodeURL: qrCodeURL ?? this.qrCodeURL,
      recommendedDistance: recommendedDistance ?? this.recommendedDistance,
      warnings: warnings ?? this.warnings,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
