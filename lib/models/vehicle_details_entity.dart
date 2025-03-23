import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VehicleDetailsEntity {
  final int vehicleId;
  final String vehicleNumber;
  final String plateNumber;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleImage;
  final String vehicleStatus;
  final String condition;
  final double fuelConsumption;
  final String fuelType;
  final String gearSystem;
  final bool hasEmergencyKit;
  final bool hasSpareTools;
  final int recommendedDistance;
  final String warnings;
  final String qrCodeURL;

  VehicleDetailsEntity({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.plateNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleImage,
    required this.vehicleStatus,
    required this.condition,
    required this.fuelConsumption,
    required this.fuelType,
    required this.gearSystem,
    required this.hasEmergencyKit,
    required this.hasSpareTools,
    required this.recommendedDistance,
    required this.warnings,
    required this.qrCodeURL,
  });

  // Improved factory method with better error handling
  factory VehicleDetailsEntity.fromMap(Map<String, dynamic> map) {
    try {
      return VehicleDetailsEntity(
        vehicleId: map['vehicleId'] is int
            ? map['vehicleId']
            : int.tryParse(map['vehicleId']?.toString() ?? '0') ?? 0,
        vehicleNumber: map['vehicleNumber']?.toString() ?? '',
        plateNumber: map['plateNumber']?.toString() ?? '',
        vehicleType: map['vehicleType']?.toString() ?? '',
        vehicleModel: map['vehicleModel']?.toString() ?? '',
        vehicleImage: map['vehicleImage']?.toString() ?? 'assets/car.png',
        vehicleStatus: map['vehicleStatus']?.toString() ?? 'Unknown',
        condition: map['condition']?.toString() ?? 'Unknown',
        fuelConsumption: map['fuelConsumption'] is double
            ? map['fuelConsumption']
            : double.tryParse(map['fuelConsumption']?.toString() ?? '0') ?? 0.0,
        fuelType: map['fuelType']?.toString() ?? 'Unknown',
        gearSystem: map['gearSystem']?.toString() ?? 'Manual',
        hasEmergencyKit: map['hasEmergencyKit'] == true,
        hasSpareTools: map['hasSpareTools'] == true,
        recommendedDistance: map['recommendedDistance'] is int
            ? map['recommendedDistance']
            : int.tryParse(map['recommendedDistance']?.toString() ?? '0') ?? 0,
        warnings: map['warnings']?.toString() ?? 'None',
        qrCodeURL: map['qrCodeURL']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error creating VehicleDetailsEntity from map: $e');
      return VehicleDetailsEntity.empty();
    }
  }

  // Safe fromFirestore method
  factory VehicleDetailsEntity.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return VehicleDetailsEntity.fromMap(data);
    } catch (e) {
      debugPrint('Error creating VehicleDetailsEntity from Firestore: $e');
      return VehicleDetailsEntity.empty();
    }
  }

  factory VehicleDetailsEntity.empty() {
    return VehicleDetailsEntity(
      vehicleId: 0,
      vehicleNumber: 'Unknown',
      plateNumber: 'Unknown',
      vehicleType: 'Unknown',
      vehicleModel: 'Unknown',
      vehicleImage: 'assets/car.png',
      vehicleStatus: 'Unknown',
      condition: 'Unknown',
      fuelConsumption: 0.0,
      fuelType: 'Unknown',
      gearSystem: 'Unknown',
      hasEmergencyKit: false,
      hasSpareTools: false,
      recommendedDistance: 0,
      warnings: 'None',
      qrCodeURL: '',
    );
  }
}
