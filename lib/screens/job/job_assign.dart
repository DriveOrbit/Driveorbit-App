import 'package:flutter/material.dart';
import 'package:driveorbit_app/widgets/job_card.dart';
import 'package:driveorbit_app/widgets/completed_job_card.dart';
import 'package:driveorbit_app/widgets/job_summary_widget.dart';
import 'dart:convert';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JobAssignedPage extends StatefulWidget {
  const JobAssignedPage({super.key});

  @override
  State<JobAssignedPage> createState() => _JobAssignedPageState();
}

class _JobAssignedPageState extends State<JobAssignedPage> {
  List<JobDetailsEntity> _history = [];
  bool _isLoading = true;
  bool _showCompleted = false; // Toggle for completed jobs visibility

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response =
          await rootBundle.loadString('assets/mock_jobdetails.json');
      final List<dynamic> decodedList = jsonDecode(response);
      final List<JobDetailsEntity> history =
          decodedList.map((item) => JobDetailsEntity.fromJson(item)).toList();

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading job data: $e');
    }
  }

  // Method to complete a job
  void _completeJob(String jobId) {
    setState(() {
      // Find the job by ID and update its status
      final index = _history.indexWhere((job) => job.historyId == jobId);
      if (index != -1) {
        // Create a new job object with completed status
        final updatedJob = JobDetailsEntity(
          historyId: _history[index].historyId,
          date: _history[index].date,
          arrivedTime: _history[index].arrivedTime,
          distance: _history[index].distance,
          duration: _history[index].duration,
          startLocation: _history[index].startLocation,
          endLocation: _history[index].endLocation,
          status: "completed", // Update status to completed
          urgency: _history[index].urgency,
          customerName: _history[index].customerName,
          customerContact: _history[index].customerContact,
          vehicleType: _history[index].vehicleType,
          estimatedFare: _history[index].estimatedFare,
          notes: _history[index].notes,
        );

        // Replace the old job with the updated one
        _history[index] = updatedJob;

        // Automatically show completed jobs when a job is completed
        _showCompleted = true;
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Job marked as completed!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate jobs into pending and completed
    final pendingJobs = _history.where((job) => job.isPending).toList();
    final completedJobs = _history.where((job) => job.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YOUR JOBS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6D6BF8),
              ),
            )
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 70,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs available',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Fixed summary at the top
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: JobSummaryWidget(jobs: _history),
                      ),

                      // Scrollable job list
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            // Pending jobs section
                            if (pendingJobs.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    'Pending Jobs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => JobCard(
                                      history: pendingJobs[index],
                                      onCompletePressed: () => _completeJob(
                                          pendingJobs[index].historyId),
                                    ),
                                    childCount: pendingJobs.length,
                                  ),
                                ),
                              ),
                            ],

                            // Completed jobs section with toggle
                            if (completedJobs.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Completed Jobs',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16.0.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: Icon(
                                          _showCompleted
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18.0.sp,
                                          color: Colors.grey[400],
                                        ),
                                        label: Text(
                                          _showCompleted ? 'Hide' : 'Show',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.0.sp,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showCompleted = !_showCompleted;
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_showCompleted)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => CompletedJobCard(
                                          job: completedJobs[index]),
                                      childCount: completedJobs.length,
                                    ),
                                  ),
                                ),
                            ],

                            // Empty state for when all jobs are completed
                            if (pendingJobs.isEmpty && completedJobs.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 24.0,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 48.0,
                                          color: Colors.green[400],
                                        ),
                                        const SizedBox(height: 12.0),
                                        Text(
                                          'All jobs completed!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16.0.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Add bottom padding
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16.0),
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
