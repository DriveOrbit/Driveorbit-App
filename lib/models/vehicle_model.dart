// Create a new file: lib/models/vehicle_model.dart
class VehicleModel {
  final String name;
  final String plateNumber;
  final String condition;
  final double fuelConsumption;
  final int recommendedDistance;
  final List<String> warnings;
  final String vehicleType;
  final String fuelType;
  final String gearSystem;
  final bool hasSpareTools;
  final bool hasEmergencyKit;
  final Map<String, MaintenanceStatus> maintenanceStatus;

  VehicleModel({
    required this.name,
    required this.plateNumber,
    required this.condition,
    required this.fuelConsumption,
    required this.recommendedDistance,
    required this.warnings,
    required this.vehicleType,
    required this.fuelType,
    required this.gearSystem,
    required this.hasSpareTools,
    required this.hasEmergencyKit,
    required this.maintenanceStatus,
  });

  // Sample data factory
  factory VehicleModel.sample() {
    return VehicleModel(
      name: 'TOYOTA KDH 201 SUPARIAL GL',
      plateNumber: 'PF-9093',
      condition: 'Good',
      fuelConsumption: 12.3,
      recommendedDistance: 1022,
      warnings: [
        'Please Check Tyre Pressure and Condition',
        'Fog Lights are not working',
      ],
      vehicleType: 'van',
      fuelType: 'Petrol',
      gearSystem: 'Auto',
      hasSpareTools: true,
      hasEmergencyKit: true,
      maintenanceStatus: {
        'Engine Oil': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Coolant Level': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Brake Fluid': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Transmission Fluid': MaintenanceStatus(
            status: 'Didn\'t check', date: 'Please check it', isOk: false),
        'Battery Health': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Tyre Pressure & Condition':
            MaintenanceStatus(status: 'NEED TO CHECK', date: '', isOk: false),
        'Brakes Condition': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Lights & Signals': MaintenanceStatus(
            status: 'Last check', date: '08/12/2024', isOk: true),
        'Wiper Blades & Fluid': MaintenanceStatus(
            status: 'Last check', date: 'Last week', isOk: true),
      },
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
