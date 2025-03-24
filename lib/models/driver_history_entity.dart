class DrivingHistoryEntity {
  final String historyId;
  final DateTime date;
  final String vehicleModel;
  final String vehicleNumber;
  final double distance;
  final Duration duration;
  final String startLocation;
  final String endLocation;

  DrivingHistoryEntity({
    required this.historyId,
    required this.date,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });

  factory DrivingHistoryEntity.fromJson(Map<String, dynamic> json) {
    return DrivingHistoryEntity(
      historyId: json['historyId'],
      date: DateTime.parse(json['date']),
      vehicleModel: json['vehicleModel'],
      vehicleNumber: json['vehicleNumber'],
      distance: json['distance'].toDouble(),
      duration: Duration(minutes: json['duration']),
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
    );
  }
}
