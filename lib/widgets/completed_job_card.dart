import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CompletedJobCard extends StatelessWidget {
  final JobDetailsEntity job;
  final VoidCallback? onTap;

  const CompletedJobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format the date and time
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final String formattedDate = dateFormatter.format(job.date);
    final String formattedTime = timeFormatter.format(job.arrivedTime);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            // Replace transparent gradient with a solid fill color
            color: Color(0xFF0A3D14), // Dark green base color
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F4B20), // Darker green
                Color(0xFF164A29), // Slightly lighter green
              ],
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Colors.green.withOpacity(0.7), // Increased opacity
              width: 1.5, // Slightly thicker border
            ),
            // Enhanced shadow for better depth
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _showCompletedJobDetails(context),
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    // Green checkmark indicator
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 14.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Job details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route information in a single line
                          Text(
                            '${job.startLocation} → ${job.endLocation}',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),

                          // Date, time, and distance - Fixed with Expanded widgets
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.access_time,
                                size: 12.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Distance chip - Added a fixed width to prevent overflow
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        '${job.distance.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletedJobDetails(BuildContext context) {
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
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
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
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Job details
                  _buildDetailRow("ID:", "#${job.historyId}"),
                  _buildDetailRow(
                      "Date:", DateFormat('MMM dd, yyyy').format(job.date)),
                  _buildDetailRow(
                      "Time:", DateFormat('hh:mm a').format(job.arrivedTime)),
                  _buildDetailRow("Customer:", job.customerName),
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

                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6D6BF8),
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
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
