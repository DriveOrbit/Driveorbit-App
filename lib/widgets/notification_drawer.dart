import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/notification_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:driveorbit_app/services/notification_service.dart';

class NotificationDrawer extends StatefulWidget {
  final NotificationService notificationService;

  const NotificationDrawer({
    super.key,
    required this.notificationService,
  });

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  bool _isLoading = true;
  bool _hasPermissionError = false;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Subscribe to notification stream for real-time updates
    widget.notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
          // Assume permission error if we have no notifications after loading
          // and the listener returned an empty list
          _hasPermissionError = notifications.isEmpty && !_isLoading;
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasPermissionError = false;
    });

    try {
      final notifications = await widget.notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
          // Assume permission error if we get empty notifications unexpectedly
          _hasPermissionError = notifications.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermissionError =
              e is FirebaseException && e.code == 'permission-denied';
        });
      }
    }
  }

  // Mark a notification as read
  void _markAsRead(String id) async {
    await widget.notificationService.markAsRead(id);
  }

  // Mark all notifications as read
  void _markAllAsRead() async {
    await widget.notificationService.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      width: 320.w, // Fixed width for consistency
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.notificationService.hasUnreadNotifications())
                        TextButton(
                          onPressed: () {
                            _markAllAsRead();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6D6BF8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                          ),
                          child: Text(
                            'Mark All Read',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadNotifications,
                        color: Colors.white70,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _hasPermissionError
                      ? _buildPermissionError()
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6D6BF8)),
            strokeWidth: 3.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading notifications...',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14.sp,
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
            size: 64.sp,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'You don\'t have any notifications yet. New notifications will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync_problem,
              size: 64.sp,
              color: Colors.amber,
            ),
            SizedBox(height: 16.h),
            Text(
              'Notification Sync Issue',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'The app is temporarily using a simplified notification system. Your notifications are still being received but may not be perfectly ordered.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Text(
                'Your admin needs to set up a custom database index for optimal performance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.amber.withOpacity(0.8),
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D6BF8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF6D6BF8),
      backgroundColor: Colors.grey[800],
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Get icon based on notification type
    IconData typeIcon = _getIconForType(notification.type);
    Color typeColor = _getColorForType(notification.type);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.grey[850] : Colors.grey[800],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: notification.isRead ? Colors.grey[700]! : typeColor,
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: typeColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and timestamp row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              // Message content
              Container(
                margin: EdgeInsets.only(top: 12.h, left: 38.w),
                child: Text(
                  notification.message,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14.sp,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'vehicle':
        return Icons.directions_car_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return const Color(0xFF6D6BF8); // Purple
      case 'warning':
        return Colors.amber; // Yellow
      case 'success':
        return Colors.green; // Green
      case 'error':
        return Colors.red; // Red
      case 'assignment':
        return Colors.blue; // Blue
      case 'vehicle':
        return Colors.orange; // Orange
      default:
        return Colors.grey; // Grey
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
