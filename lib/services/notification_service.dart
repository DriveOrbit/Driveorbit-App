import 'dart:convert';
import 'package:driveorbit_app/models/notification_model.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final String _prefKey = 'user_notifications';
  List<NotificationModel> _notifications = [];
  bool _hasUnreadNotifications = false;

  // Load notifications from JSON file
  Future<List<NotificationModel>> loadSampleNotifications() async {
    try {
      // Load notifications from JSON file
      final String response =
          await rootBundle.loadString('assets/mock_notifications.json');
      final List<dynamic> jsonData = json.decode(response);

      _notifications = jsonData
          .map((item) => NotificationModel(
                id: item['id'],
                title: item['title'],
                message: item['message'],
                timestamp: DateTime.parse(item['timestamp']),
                isRead: item['isRead'],
                type: item['type'],
              ))
          .toList();

      // Sort notifications by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Check for unread notifications
      _updateUnreadStatus();
      return _notifications;
    } catch (e) {
      print('Error loading notifications: $e');
      // If there's an error, return sample data as fallback
      return _loadFallbackNotifications();
    }
  }

  // Fallback method in case JSON file can't be loaded
  List<NotificationModel> _loadFallbackNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Assignment',
        message: 'You have been assigned a new vehicle for tomorrow.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'info',
      ),
      NotificationModel(
        id: '2',
        title: 'Maintenance Alert',
        message:
            'Vehicle KL-01-AB-1234 is scheduled for maintenance next week.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'alert',
      ),
      NotificationModel(
        id: '3',
        title: 'Trip Completed',
        message: 'Your trip to Chennai has been completed successfully.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'success',
        isRead: true,
      ),
    ];

    _updateUnreadStatus();
    return _notifications;
  }

  List<NotificationModel> getNotifications() {
    return _notifications;
  }

  bool hasUnreadNotifications() {
    return _hasUnreadNotifications;
  }

  void _updateUnreadStatus() {
    _hasUnreadNotifications =
        _notifications.any((notification) => !notification.isRead);
  }

  void markAsRead(String id) {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].id == id && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }

    _updateUnreadStatus();
    _saveNotifications(); // Save changes to shared preferences
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _hasUnreadNotifications = false;
    _saveNotifications(); // Save changes to shared preferences
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationList = _notifications
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'message': n.message,
                'timestamp': n.timestamp.toIso8601String(),
                'isRead': n.isRead,
                'type': n.type,
              })
          .toList();

      await prefs.setString(_prefKey, jsonEncode(notificationList));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Load saved notifications from SharedPreferences
  Future<void> loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsStr = prefs.getString(_prefKey);

      if (notificationsStr != null && notificationsStr.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(notificationsStr);
        _notifications = decodedList
            .map((item) => NotificationModel(
                  id: item['id'],
                  title: item['title'],
                  message: item['message'],
                  timestamp: DateTime.parse(item['timestamp']),
                  isRead: item['isRead'],
                  type: item['type'],
                ))
            .toList();

        _updateUnreadStatus();
      } else {
        // If no saved notifications, load from JSON file
        await loadSampleNotifications();
      }
    } catch (e) {
      print('Error loading saved notifications: $e');
      // If there's an error loading from SharedPreferences, load from JSON file
      await loadSampleNotifications();
    }
  }

  // Add a new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification); // Add to beginning of the list
    _updateUnreadStatus();
    _saveNotifications();
  }

  // Delete a notification
  void deleteNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    _updateUnreadStatus();
    _saveNotifications();
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications = [];
    _hasUnreadNotifications = false;
    _saveNotifications();
  }

  // Check if there are unread job assignments
  bool hasUnreadJobAssignments() {
    return _notifications.any((notification) =>
        !notification.isRead &&
        (notification.title.toLowerCase().contains('assign') ||
            notification.message.toLowerCase().contains('assign')));
  }

  // Get count of unread job assignments
  int getUnreadJobAssignmentCount() {
    return _notifications
        .where((notification) =>
            !notification.isRead &&
            (notification.title.toLowerCase().contains('assign') ||
                notification.message.toLowerCase().contains('assign')))
        .length;
  }
}
