import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CompletedJobCard extends StatefulWidget {
  final JobDetailsEntity job;

  const CompletedJobCard({
    super.key,
    required this.job,
  });

  @override
  State<CompletedJobCard> createState() => _CompletedJobCardState();
}

class _CompletedJobCardState extends State<CompletedJobCard>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false; // Add flag to prevent navigation issues
  bool _isExpanded = false; // Track expanded state
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Safe navigation method
  void _safeNavigate(VoidCallback navigationAction) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Add a small delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 50), () {
      navigationAction();

      // Reset flag after navigation occurs
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.job.getStatusColor().withOpacity(0.5),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with status pill and icon buttons
                _buildTopSection(),

                // Main content - visible in both collapsed and expanded states
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location and details
                      _buildMainContent(),

                      // Stats row (distance, duration, time)
                      _buildStatsRow(),

                      // Expandable content
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey[800], height: 32.h),
                            _buildExpandedContent(),
                          ],
                        ),
                      ),

                      // Bottom action buttons
                      _buildBottomActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Top section with status badge and actions
  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status badge with pulsing animation
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: widget.job.getStatusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: widget.job.getStatusColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.job.isComplete
                      ? Icons.check_circle
                      : Icons.directions_car,
                  color: widget.job.getStatusColor(),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  widget.job.statusDisplayName.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.job.getStatusColor(),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Job ID badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '#${widget.job.historyId.substring(0, Math.min(6, widget.job.historyId.length))}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Expand/Collapse indicator
          IconButton(
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // Main content section - visible in both states
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),

        // Date with nice formatting
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event,
                color: const Color(0xFF6D6BF8),
                size: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              DateFormat('EEEE, MMM dd, yyyy').format(widget.job.date),
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),

        // Divider with dots
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 21.w),
          child: Column(
            children: List.generate(
              3,
              (index) => Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 2.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        // From location
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trip_origin,
                color: Colors.green,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    widget.job.startLocation,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Divider with dots
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 21.w),
          child: Column(
            children: List.generate(
              3,
              (index) => Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 2.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        // To location
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    widget.job.endLocation,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),
      ],
    );
  }

  // Stats row with distance, duration, time
  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            icon: Icons.straighten,
            value: "${widget.job.distance} km",
            color: Colors.blue,
          ),
          Container(
            height: 24.h,
            width: 1,
            color: Colors.grey[700],
          ),
          _buildStatChip(
            icon: Icons.access_time,
            value: "${widget.job.duration} min",
            color: Colors.orange,
          ),
          Container(
            height: 24.h,
            width: 1,
            color: Colors.grey[700],
          ),
          _buildStatChip(
            icon: Icons.schedule,
            value: DateFormat('hh:mm a').format(widget.job.arrivedTime),
            color: const Color(0xFF6D6BF8),
          ),
        ],
      ),
    );
  }

  // Expanded content - only visible when expanded
  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Additional info header
        Text(
          'Additional Information',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),

        // Additional details in a grid
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              // Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Customer',
                      value: widget.job.customerName,
                      icon: Icons.person,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Vehicle',
                      value: widget.job.vehicleType.isEmpty
                          ? 'Not Specified'
                          : widget.job.vehicleType,
                      icon: Icons.directions_car,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Contact',
                      value: widget.job.customerContact.isEmpty
                          ? 'N/A'
                          : widget.job.customerContact,
                      icon: Icons.phone,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Urgency',
                      value: widget.job.urgency.isEmpty
                          ? 'Normal'
                          : widget.job.urgency.capitalize(),
                      icon: Icons.priority_high,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notes section if available
        if (widget.job.notes.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            "Notes",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF6D6BF8).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.job.notes,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ),
        ],

        SizedBox(height: 16.h),
      ],
    );
  }

  // Bottom action buttons
  Widget _buildBottomActions() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // View details button
          Expanded(
            child: TextButton.icon(
              icon: Icon(
                _isExpanded ? Icons.visibility_off : Icons.visibility,
                size: 16.sp,
                color: const Color(0xFF6D6BF8),
              ),
              label: Text(
                _isExpanded ? "Hide Details" : "View Details",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: const Color(0xFF6D6BF8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  if (_isExpanded) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              },
            ),
          ),

          // Divider
          Container(
            height: 24.h,
            width: 1,
            color: Colors.grey[700],
          ),

          // Full details button
          Expanded(
            child: TextButton.icon(
              icon: Icon(
                Icons.info_outline,
                size: 16.sp,
                color: Colors.grey[400],
              ),
              label: Text(
                "Full Details",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                _safeNavigate(() {
                  _showCompletedJobDetails(context, widget.job);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stat chip widget
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: color,
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Detail item widget for expanded content
  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: Colors.grey[400],
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Show detailed info for completed job in a modal dialog
  void _showCompletedJobDetails(BuildContext context, JobDetailsEntity job) {
    showDialog(
      context: context,
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
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "Completed Job",
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
                        onPressed: () {
                          // Use safe navigation when closing
                          _safeNavigate(() {
                            Navigator.of(context).pop();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Details with all information
                  _buildDetailRow("ID:", "#${job.historyId}"),
                  _buildDetailRow(
                      "Date:", DateFormat('MMM dd, yyyy').format(job.date)),
                  _buildDetailRow("Time:", job.formattedTime),
                  _buildDetailRow("Customer:", job.customerName),
                  _buildDetailRow("Contact:", job.customerContact),
                  _buildDetailRow("Vehicle Type:", job.vehicleType),
                  _buildDetailRow("From:", job.startLocation),
                  _buildDetailRow("To:", job.endLocation),
                  _buildDetailRow(
                      "Distance:", "${job.distance.toStringAsFixed(1)} km"),
                  _buildDetailRow("Duration:", "${job.duration} minutes"),

                  // Notes section if available
                  if (job.notes.isNotEmpty) ...[
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
                        job.notes,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],

                  // Close button
                  SizedBox(height: 24.h),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _safeNavigate(() {
                          Navigator.of(context).pop();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D6BF8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
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

  // Helper for building detail rows
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

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
