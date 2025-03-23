import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class JobCard extends StatefulWidget {
  final JobDetailsEntity history;
  final VoidCallback? onCompletePressed;

  const JobCard({
    super.key,
    required this.history,
    this.onCompletePressed,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isCompletingJob = false;
  bool _isNavigating = false; // Add flag to prevent multiple navigations

  @override
  Widget build(BuildContext context) {
    // Format the date
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final String formattedDate = dateFormatter.format(widget.history.date);

    // Format the time
    final timeFormatter = DateFormat('hh:mm a');
    final String formattedTime =
        timeFormatter.format(widget.history.arrivedTime);

    // Get status color for card border
    final bool isCompleted = widget.history.isCompleted;
    final Color statusColor = widget.history.getStatusColor();
    final Color urgencyColor = widget.history.getUrgencyColor();

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: statusColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator at the top
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        widget.history.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (widget.history.urgency.toLowerCase() == 'high')
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: Colors.red,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'URGENT',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and id row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14.sp,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            widget.history.formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '#${widget.history.historyId}',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Route info with enhanced design (customer info section removed)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D6BF8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: const Color(0xFF6D6BF8),
                                size: 16.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FROM',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[400],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    widget.history.startLocation,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 15.w),
                          child: Row(
                            children: [
                              Container(
                                height: 30.h,
                                width: 2,
                                color: Colors.grey[700],
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${widget.history.distance.toStringAsFixed(1)} km',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 16.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[400],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    widget.history.endLocation,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Trip stats in a more organized layout - modified to remove fare
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTripStatNew(
                        icon: Icons.access_time,
                        label: widget.history.formattedTime,
                        color: Colors.orange,
                      ),
                      _buildTripStatNew(
                        icon: Icons.timer,
                        label: "${widget.history.duration} min",
                        color: Colors.purple,
                      ),
                      // Removed money/fare stat
                    ],
                  ),

                  if (widget.history.notes.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFF6D6BF8).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: const Color(0xFF6D6BF8),
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'NOTES',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6D6BF8),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            widget.history.notes,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 16.h),

                  // Actions row - improved buttons with loading state
                  isCompleted
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Completed Job',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: _isCompletingJob
                                    ? SizedBox(
                                        width: 18.sp,
                                        height: 18.sp,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : Icon(
                                        Icons.check_circle_outline,
                                        size: 18.sp,
                                      ),
                                label: Text(
                                  _isCompletingJob
                                      ? "Processing..."
                                      : "Complete",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                onPressed: _isCompletingJob
                                    ? null
                                    : () {
                                        setState(() {
                                          _isCompletingJob = true;
                                        });

                                        // Call the completion callback
                                        if (widget.onCompletePressed != null) {
                                          widget.onCompletePressed!();
                                        }

                                        // Reset state after a delay
                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          if (mounted) {
                                            setState(() {
                                              _isCompletingJob = false;
                                            });
                                          }
                                        });
                                      },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.navigation,
                                  size: 18.sp,
                                ),
                                label: Text(
                                  "Navigate",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D6BF8),
                                  side: const BorderSide(
                                      color: Color(0xFF6D6BF8)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Navigation started"),
                                      backgroundColor: Color(0xFF6D6BF8),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                  // Additional actions
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: Colors.white70,
                        ),
                        label: Text(
                          "View Details",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          // Show job details
                          showJobDetailsDialog(context);
                        },
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        icon: Icon(
                          Icons.call,
                          size: 16.sp,
                          color: Colors.green,
                        ),
                        label: Text(
                          "Fleet Manager",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          _makePhoneCall(
                              '+94771234567'); // Replace with your fleet manager number
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to make phone calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  // Old trip stat widget - keeping for backward compatibility
  Widget _buildTripStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Improved trip stat widget
  Widget _buildTripStatNew({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Add a safe navigation method to prevent crashes
  void _safeNavigate(VoidCallback navigationAction) {
    if (_isNavigating) return; // Prevent multiple taps

    setState(() {
      _isNavigating = true;
    });

    // Add a small delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 50), () {
      navigationAction();
    });
  }

  // Show job details dialog with safe navigation
  void showJobDetailsDialog(BuildContext context) {
    if (_isNavigating) return;

    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        color: const Color(0xFF6D6BF8),
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "Job Details",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.close, color: Colors.white, size: 20.sp),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Status indicator
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding:
                        EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: widget.history.getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: widget.history.getStatusColor().withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: widget.history.getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          widget.history.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: widget.history.getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details
                  _buildDetailRow("ID:", "#${widget.history.historyId}"),
                  _buildDetailRow("Date:",
                      DateFormat('MMM dd, yyyy').format(widget.history.date)),
                  _buildDetailRow("Time:",
                      DateFormat('hh:mm a').format(widget.history.arrivedTime)),
                  _buildDetailRow("Customer:", widget.history.customerName),
                  _buildDetailRow("Contact:", widget.history.customerContact),
                  _buildDetailRow("Vehicle Type:", widget.history.vehicleType),
                  _buildDetailRow("From:", widget.history.startLocation),
                  _buildDetailRow("To:", widget.history.endLocation),
                  _buildDetailRow("Distance:",
                      "${widget.history.distance.toStringAsFixed(1)} km"),
                  _buildDetailRow(
                      "Duration:", "${widget.history.duration} minutes"),
                  // Removed Estimated Fare detail row

                  // Notes section
                  if (widget.history.notes.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      "Notes:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        widget.history.notes,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],

                  // Actions
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!widget.history.isCompleted)
                        Flexible(
                          child: SizedBox(
                            width: 140.w,
                            child: ElevatedButton.icon(
                              icon: _isCompletingJob
                                  ? SizedBox(
                                      width: 18.sp,
                                      height: 18.sp,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check_circle_outline,
                                      size: 18.sp,
                                    ),
                              label: Text(
                                _isCompletingJob ? "Processing..." : "Complete",
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onPressed: _isCompletingJob
                                  ? null
                                  : () {
                                      setState(() {
                                        _isCompletingJob = true;
                                      });

                                      // Use safe navigation when popping dialog
                                      _safeNavigate(() {
                                        Navigator.of(context).pop();

                                        if (widget.onCompletePressed != null) {
                                          widget.onCompletePressed!();
                                        }
                                      });

                                      // Reset state after a delay
                                      Future.delayed(const Duration(seconds: 2),
                                          () {
                                        if (mounted) {
                                          setState(() {
                                            _isCompletingJob = false;
                                            _isNavigating = false;
                                          });
                                        }
                                      });
                                    },
                            ),
                          ),
                        ),
                      SizedBox(width: 8.w),
                      TextButton(
                        onPressed: () {
                          // Safe navigation when closing dialog
                          _safeNavigate(() {
                            Navigator.of(context).pop();
                          });

                          // Reset navigation flag after a delay
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                _isNavigating = false;
                              });
                            }
                          });
                        },
                        child: Text(
                          "Close",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6D6BF8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Reset navigation flag when dialog is closed
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
