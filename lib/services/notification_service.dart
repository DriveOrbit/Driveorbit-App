import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _cachedNotifications = [];
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  // Stream controller to broadcast notifications to listeners
  final _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  // Getter for the stream
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  // Flag to track if we're falling back to simple query
  bool _isUsingSimpleQuery = false;

  // Constructor - initialize the service
  NotificationService() {
    // Start listening when the service is created
    _initNotificationListener();
  }

  // Initialize the real-time notification listener
  void _initNotificationListener() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Cancel any existing subscription
    _notificationSubscription?.cancel();

    try {
      debugPrint(
          '📬 Setting up notification listener for user: ${currentUser.uid}');

      // SIMPLIFIED APPROACH: Use a simple query without complex ordering
      // This avoids the need for a composite index
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid);

      // Don't use orderBy in the query - we'll sort in memory instead

      // Subscribe to real-time updates with error handling
      _notificationSubscription = query.snapshots().listen(
        (QuerySnapshot snapshot) {
          // Parse documents
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();

          // Sort by timestamp (descending) in memory
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          _cachedNotifications = notifications;

          // Reset flag - using simple query by default now
          _isUsingSimpleQuery = true;

          // Broadcast updated notifications
          _notificationsController.add(_cachedNotifications);

          debugPrint(
              '✅ Loaded ${_cachedNotifications.length} notifications with simple query');
        },
        onError: (error) {
          debugPrint('❌ Error in notification query: $error');
          // Still broadcast empty list on error to avoid UI breaks
          _notificationsController.add([]);

          // Handle permission denied errors specifically
          if (error is FirebaseException && error.code == 'permission-denied') {
            debugPrint(
                '⚠️ Permission denied for notifications: ${error.message}');
            debugPrint(
                'Firestore security rules need to be updated to allow notification access');
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Error setting up notification listener: $e');
      // Still broadcast empty list on error to avoid UI breaks
      _notificationsController.add([]);
    }
  }

  // Fallback method is no longer needed as we're using simple query by default
  void _fallbackToSimpleQuery() {
    // This method is kept for backward compatibility but is effectively a no-op now
    debugPrint(
        '⚠️ _fallbackToSimpleQuery called but we\'re already using simple queries');
  }

  // Get current notifications (use cached if available) with better error handling
  Future<List<NotificationModel>> getNotifications() async {
    if (_cachedNotifications.isNotEmpty) {
      return _cachedNotifications;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      debugPrint('🔄 Fetching notifications for user: ${currentUser.uid}');

      // Always use the simple query approach to avoid index errors
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // Sort by timestamp (descending) in memory
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _cachedNotifications = notifications;

      debugPrint('✅ Fetched ${_cachedNotifications.length} notifications');
      return _cachedNotifications;
    } catch (e) {
      // Handle errors
      debugPrint('❌ Error fetching notifications: $e');

      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('⚠️ Permission denied for notifications: ${e.message}');
        debugPrint(
            'Firestore security rules need to be updated to allow notification access');
      }

      return [];
    }
  }

  // Check if there are any unread notifications
  bool hasUnreadNotifications() {
    return _cachedNotifications.any((notification) => !notification.isRead);
  }

  // Get count of unread notifications
  int unreadCount() {
    return _cachedNotifications
        .where((notification) => !notification.isRead)
        .length;
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update in Firestore
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local cache as well
      final index =
          _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cachedNotifications[index].isRead = true;
        // Broadcast updated notifications
        _notificationsController.add([..._cachedNotifications]);
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get a batch to perform multiple operations
      final batch = _firestore.batch();

      // Get all unread notifications
      QuerySnapshot snapshot;

      try {
        // Try standard query first
        snapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();
      } catch (e) {
        // If it fails, get all notifications and filter in memory
        snapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
      }

      // Add each update to the batch - only for unread notifications
      for (var doc in snapshot.docs) {
        // Check if doc is already read (if we're using the unfiltered query)
        final data = doc.data() as Map<String, dynamic>;
        if (data['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      // Commit the batch
      await batch.commit();

      // Update local cache
      for (var notification in _cachedNotifications) {
        notification.isRead = true;
      }

      // Broadcast updated notifications
      _notificationsController.add([..._cachedNotifications]);
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationsController.close();
  }

  // Get required index information for user/admin
  static String getRequiredIndexUrl() {
    return 'https://console.firebase.google.com/project/_/firestore/indexes';
  }

  static String getRequiredIndexFields() {
    return 'Collection: notifications\nFields: userId Ascending, timestamp Descending';
  }
}
