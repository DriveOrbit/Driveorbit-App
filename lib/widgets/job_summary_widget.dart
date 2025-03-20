import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';

class JobSummaryWidget extends StatelessWidget {
  final List<JobDetailsEntity> jobs;

  const JobSummaryWidget({
    Key? key,
    required this.jobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate summary statistics
    final int totalJobs = jobs.length;
    final int pendingJobs = jobs.where((job) => job.isPending).length;
    final int completedJobs = jobs.where((job) => job.isCompleted).length;
    final double totalDistance = jobs.fold(0, (sum, job) => sum + job.distance);
    final double totalEarnings =
        jobs.fold(0, (sum, job) => sum + job.estimatedFare);

    // Find urgent jobs
    final urgentJobs = jobs
        .where((job) => job.urgency.toLowerCase() == 'high' && job.isPending)
        .toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF2D2D2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job Summary',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Total: $totalJobs jobs',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          Divider(color: Colors.grey.withOpacity(0.3), height: 24.h),

          // Stats grid
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildStatCard(
                icon: Icons.pending_actions,
                value: pendingJobs.toString(),
                label: 'Pending',
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.check_circle_outline,
                value: completedJobs.toString(),
                label: 'Completed',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.route,
                value: '${totalDistance.toStringAsFixed(1)} km',
                label: 'Total Distance',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.attach_money,
                value: 'Rs ${totalEarnings.toInt()}',
                label: 'Est. Earnings',
                color: const Color(0xFF6D6BF8),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Urgent jobs section
          if (urgentJobs.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.priority_high, color: Colors.red, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  'Urgent Jobs',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.w),
                itemCount: urgentJobs.length > 2 ? 2 : urgentJobs.length,
                itemBuilder: (context, index) {
                  final job = urgentJobs[index];
                  return ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    title: Text(
                      '#${job.historyId}: ${job.startLocation} → ${job.endLocation}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Customer: ${job.customerName} • ${job.distance.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 14.sp),
                    onTap: () {
                      // Navigate to job details or show dialog
                      _showJobDetailsSheet(context, job);
                    },
                  );
                },
              ),
            ),
            if (urgentJobs.length > 2)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 8.w),
                child: Text(
                  '+ ${urgentJobs.length - 2} more urgent jobs',
                  style: GoogleFonts.poppins(
                    color: Colors.red[300],
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 144.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetailsSheet(BuildContext context, JobDetailsEntity job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Urgent Job Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('ID:', '#${job.historyId}'),
            _buildInfoRow('Customer:', job.customerName),
            _buildInfoRow('Contact:', job.customerContact),
            _buildInfoRow('From:', job.startLocation),
            _buildInfoRow('To:', job.endLocation),
            _buildInfoRow('Distance:', '${job.distance.toStringAsFixed(1)} km'),
            _buildInfoRow('Est. Duration:', '${job.duration} min'),
            _buildInfoRow('Est. Fare:', 'Rs ${job.estimatedFare.toInt()}'),
            if (job.notes.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                'Notes:',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 6.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
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
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: Text(
                      'Navigate',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D6BF8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation started'),
                          backgroundColor: Color(0xFF6D6BF8),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: Text(
                      'Call',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${job.customerName}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
