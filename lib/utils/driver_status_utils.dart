import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to manage driver status throughout the app
class DriverStatusUtils {
  // Status mapping for consistent usage
  static const Map<String, Map<String, dynamic>> statusMap = {
    'active': {
      'display': 'Active',
      'color': Color(0xFF4CAF50), // Green
      'firestore_value': 'active',
    },
    'break': {
      'display': 'Taking a break',
      'color': Color(0xFFFF9800), // Orange
      'firestore_value': 'break',
    },
    'inactive': {
      'display': 'Unavailable',
      'color': Color(0xFFF44336), // Red
      'firestore_value': 'inactive',
    },
  };

  /// Convert a Firestore status string to a display name
  static String getDisplayName(String status) {
    final lowerStatus = status.toLowerCase();
    return statusMap[lowerStatus]?['display'] ?? status;
  }

  /// Get the color associated with a status
  static Color getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    return statusMap[lowerStatus]?['color'] ?? Colors.grey;
  }

  /// Get the Firestore value for a status
  static String getFirestoreValue(String displayName) {
    for (var entry in statusMap.entries) {
      if (entry.value['display'] == displayName) {
        return entry.value['firestore_value'];
      }
    }
    return displayName.toLowerCase().replaceAll(' ', '_');
  }

  /// Update driver status in Firestore
  static Future<void> updateDriverStatus({
    required String status,
    required BuildContext context,
    bool showSnackbar = false, // Change default to false
  }) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user document reference
      final userDocRef =
          FirebaseFirestore.instance.collection('drivers').doc(currentUser.uid);

      // Update the status field
      await userDocRef.update({
        'status': status,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      // Show success message if requested (now off by default)
      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${getDisplayName(status)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return;
    } catch (e) {
      // Re-throw the exception to be handled by the caller
      rethrow;
    }
  }

  /// Get current driver status from Firestore
  static Future<String> getCurrentStatus() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('Driver profile not found');
      }

      final userData = userDoc.data()!;
      return userData['status'] ?? 'active'; // Default to active
    } catch (e) {
      // Default to active if there's an error
      return 'active';
    }
  }
}
