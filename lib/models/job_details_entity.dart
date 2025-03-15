class JobDetailsEntity {
  final String historyId;
  final DateTime date;
  final DateTime arrivedTime; // New field
  final double distance;
  final Duration duration;
  final String startLocation;
  final String endLocation;

  JobDetailsEntity({
    required this.historyId,
    required this.date,
    required this.arrivedTime, // New field
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });

  factory JobDetailsEntity.fromJson(Map<String, dynamic> json) {
    return JobDetailsEntity(
      historyId: json['historyId'],
      date: DateTime.parse(json['date']),
      arrivedTime: DateTime.parse(json['arrivedTime']), // New field
      distance: json['distance'].toDouble(),
      duration: Duration(minutes: json['duration']),
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
    );
  }
}