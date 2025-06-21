import 'package:driveorbit_app/models/vehicle_details_entity.dart';

class VehicleModel {
  final VehicleDetailsEntity details;
  final String documentId;

  // Maintenance status data
  final Map<String, dynamic>? maintenanceStatus;

  VehicleModel({
    required this.details,
    required this.documentId,
    this.maintenanceStatus,
  });

  factory VehicleModel.fromEntity(
      VehicleDetailsEntity entity, String documentId) {
    return VehicleModel(
      details: entity,
      documentId: documentId,
    );
  }

  // Helper to create an empty model
  factory VehicleModel.empty() {
    return VehicleModel(
      details: VehicleDetailsEntity.empty(),
      documentId: '',
    );
  }
}

class MaintenanceStatus {
  final String status;
  final String date;
  final bool isOk;

  MaintenanceStatus({
    required this.status,
    required this.date,
    required this.isOk,
  });
}
