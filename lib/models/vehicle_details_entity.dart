class VehicleDetailsEntity {
  final int vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleImage;
  final String vehicleStatus;

  VehicleDetailsEntity({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleImage,
    required this.vehicleStatus,
  });

  factory VehicleDetailsEntity.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsEntity(
      vehicleId: json['vehicleId'],
      vehicleNumber: json['vehicleNumber'],
      vehicleType: json['vehicleType'],
      vehicleModel: json['vehicleModel'],
      vehicleImage: json['vehicleImage'],
      vehicleStatus: json['vehicleStatus'],
    );
  }
}
