import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driveorbit_app/models/notification_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

class NotificationDrawer extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;
  final bool hasUnreadNotifications;

  const NotificationDrawer({
    Key? key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    required this.hasUnreadNotifications,
  }) : super(key: key);

  // Get notification color based on type
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red[700]!;
      case 'success':
        return Colors.green[700]!;
      case 'info':
      default:
        return Colors.blue[700]!;
    }
  }

  // Get notification icon based on type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_rounded;
      case 'success':
        return Icons.check_circle_outline;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  // Format timestamp to readable form
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Divide notifications into categories
    final assignmentNotifications = notifications
        .where((n) =>
            n.title.toLowerCase().contains('assign') ||
            n.message.toLowerCase().contains('assign'))
        .toList();

    final alertNotifications = notifications
        .where((n) => n.type == 'alert' && !assignmentNotifications.contains(n))
        .toList();

    final otherNotifications = notifications
        .where((n) =>
            !assignmentNotifications.contains(n) &&
            !alertNotifications.contains(n))
        .toList();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      // Remove the backgroundColor as we'll use a blur overlay instead
      backgroundColor: Colors.transparent,
      elevation: 0, // Remove elevation as it conflicts with the blur effect
      child: Stack(
        children: [
          // Background blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color:
                  Colors.black.withOpacity(0.6), // Semi-transparent background
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Notification content
          SafeArea(
            child: Column(
              children: [
                // Drawer header - removed close button and adjusted layout
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]
                        ?.withOpacity(0.8), // Semi-transparent header
                    border: const Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasUnreadNotifications)
                        TextButton(
                          onPressed: onMarkAllAsRead,
                          child: Text(
                            'Mark all as read',
                            style: TextStyle(
                              color: Colors.blue[400],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Notifications content
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Divide notifications into categories
    final assignmentNotifications = notifications
        .where((n) =>
            n.title.toLowerCase().contains('assign') ||
            n.message.toLowerCase().contains('assign'))
        .toList();

    final alertNotifications = notifications
        .where((n) => n.type == 'alert' && !assignmentNotifications.contains(n))
        .toList();

    final otherNotifications = notifications
        .where((n) =>
            !assignmentNotifications.contains(n) &&
            !alertNotifications.contains(n))
        .toList();

    return ListView(
      children: [
        // Assignments section (highest priority)
        if (assignmentNotifications.isNotEmpty)
          _buildNotificationSection(
            'New Assignments',
            assignmentNotifications,
            Colors.purple[700]!,
            true, // Make it more prominent
          ),

        // Alerts section (high priority)
        if (alertNotifications.isNotEmpty)
          _buildNotificationSection(
              'Alerts', alertNotifications, Colors.red[700]!, false),

        // Other notifications section
        if (otherNotifications.isNotEmpty)
          _buildNotificationSection(
              'General', otherNotifications, Colors.blue[700]!, false),
      ],
    );
  }

  // Helper method to build a notification section
  Widget _buildNotificationSection(
    String title,
    List<NotificationModel> sectionNotifications,
    Color sectionColor,
    bool isPriority,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          color: isPriority ? sectionColor.withOpacity(0.15) : null,
          padding: EdgeInsets.symmetric(
              horizontal: 16.w, vertical: isPriority ? 12.h : 8.h),
          child: Row(
            children: [
              // Add an indicator icon for priority sections
              if (isPriority) ...[
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: sectionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: sectionColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isPriority ? Colors.white : Colors.grey[400],
                  fontSize: isPriority ? 16.sp : 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Show count of unread items in this section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sectionNotifications.length}',
                  style: TextStyle(
                    color: sectionColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notification items in this section
        ...sectionNotifications
            .map((notification) => _buildNotificationItem(notification)),

        // Divider between sections
        Divider(color: Colors.grey[900], height: 1),
      ],
    );
  }

  // Individual notification item
  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          onMarkAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : Colors.grey[900],
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _getNotificationColor(notification.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
