import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final String userId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.userId,
    this.isRead = false,
  });

  // Convert from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse the timestamp (can be either Timestamp, string or DateTime)
    DateTime parsedTimestamp;
    if (data['timestamp'] is Timestamp) {
      parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(data['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: parsedTimestamp,
      type: data['type'] ?? 'info',
      userId: data['userId'] ?? '',
      isRead: data['isRead'] ?? false,
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'userId': userId,
      'isRead': isRead,
    };
  }
}
