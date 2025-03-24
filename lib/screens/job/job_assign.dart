import 'package:flutter/material.dart';
import 'package:driveorbit_app/widgets/job_card.dart';
import 'package:driveorbit_app/widgets/completed_job_card.dart';
import 'package:driveorbit_app/widgets/job_summary_widget.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driveorbit_app/screens/vehicle_dasboard/map_page.dart'; // Import the map page

class JobAssignedPage extends StatefulWidget {
  const JobAssignedPage({super.key});

  @override
  State<JobAssignedPage> createState() => _JobAssignedPageState();
}

class _JobAssignedPageState extends State<JobAssignedPage> {
  List<JobDetailsEntity> _history = [];
  bool _isLoading = true;
  bool _showCompleted = false; // Toggle for completed jobs visibility
  String _errorMessage = '';
  String? _currentVehicleId;
  bool _isNavigatingBack = false; // Flag to track if we're navigating back

  @override
  void initState() {
    super.initState();
    _loadCurrentVehicleId();
  }

  // First load current vehicle ID, then use it to fetch jobs
  Future<void> _loadCurrentVehicleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get vehicle ID from preferences
      String? vehicleId = prefs.getString('current_vehicle_id');

      // If no vehicle ID in preferences, try to get from current job
      if (vehicleId == null || vehicleId.isEmpty) {
        final currentJobId = prefs.getString('current_job_id');

        if (currentJobId != null && currentJobId.isNotEmpty) {
          final jobDoc = await FirebaseFirestore.instance
              .collection('jobs')
              .doc(currentJobId)
              .get();

          if (jobDoc.exists && jobDoc.data() != null) {
            vehicleId = jobDoc.data()!['vehicleId']?.toString();
          }
        }
      }

      setState(() {
        _currentVehicleId = vehicleId;
      });

      // Now load jobs
      await _loadJobsFromFirestore(vehicleId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading vehicle data: $e';
      });
      debugPrint('Error loading vehicle ID: $e');
    }
  }

  Future<void> _loadJobsFromFirestore(String? vehicleId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get current user for driver ID
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;

      // Create query to fetch work assignments
      Query query = FirebaseFirestore.instance.collection('work_assignments');

      // If we have vehicle ID, filter by it
      if (vehicleId != null && vehicleId.isNotEmpty) {
        query = query.where('vehicleId', isEqualTo: vehicleId);
      }
      // Otherwise, if we have user ID, filter by driver ID
      else if (userId != null) {
        // Check if user has a driver ID in their profile
        final userDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final driverId = userDoc.data()!['driverId'];
          if (driverId != null && driverId.isNotEmpty) {
            query = query.where('driverId', isEqualTo: driverId);
          } else {
            // Fallback - use the user ID directly
            query = query.where('driverId', isEqualTo: userId);
          }
        } else {
          // No driver profile, use user ID as fallback
          query = query.where('driverId', isEqualTo: userId);
        }
      }

      // Execute the query
      final QuerySnapshot snapshot = await query.get();

      if (mounted) {
        // Convert documents to JobDetailsEntity objects
        final List<JobDetailsEntity> jobs = snapshot.docs.map((doc) {
          return JobDetailsEntity.fromFirestore(doc);
        }).toList();

        setState(() {
          _history = jobs;
          _isLoading = false;

          // If we found jobs but don't have a vehicle ID saved, get it from the first job
          if (_currentVehicleId == null &&
              jobs.isNotEmpty &&
              jobs[0].vehicleId.isNotEmpty) {
            _currentVehicleId = jobs[0].vehicleId;
            _saveCurrentVehicleId(jobs[0].vehicleId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading job data: $e';
        });
      }
      debugPrint('Error loading jobs: $e');
    }
  }

  // Save current vehicle ID to preferences for future use
  Future<void> _saveCurrentVehicleId(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_vehicle_id', vehicleId);
    } catch (e) {
      debugPrint('Error saving vehicle ID: $e');
    }
  }

  // Method to complete a job
  Future<void> _completeJob(String jobId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Processing..."),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // First update the local state for immediate UI feedback
      setState(() {
        // Find the job by ID and update its status
        final index = _history.indexWhere((job) => job.historyId == jobId);
        if (index != -1) {
          // Create a new job object with completed status
          final updatedJob = JobDetailsEntity(
            historyId: _history[index].historyId,
            date: DateTime.parse(_history[index].dateString),
            arrivedTime: DateTime.parse(_history[index].arrivedTimeString),
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
            driverId: _history[index].driverId,
            vehicleId: _history[index].vehicleId,
            isComplete: true, // Mark as complete
          );

          // Replace the old job with the updated one
          _history[index] = updatedJob;

          // Automatically show completed jobs when a job is completed
          _showCompleted = true;
        }
      });

      // Then update Firestore - Fix the query to find the document to update
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('assignId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // If the job is not found by assignId, try searching by document ID
        try {
          // Try using the jobId directly as the document ID
          await FirebaseFirestore.instance
              .collection('work_assignments')
              .doc(jobId)
              .update({
            'status': 'completed',
            'isComplete': true,
            'completedAt': FieldValue.serverTimestamp(),
          });

          // Show success message
          _showSuccessMessage();
          return;
        } catch (e) {
          debugPrint('Error updating using document ID: $e');
          // Continue to the error handling below
        }
      } else {
        // Update the document with new status
        await snapshot.docs.first.reference.update({
          'status': 'completed',
          'isComplete': true,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        _showSuccessMessage();
        return;
      }

      // If we get here, no document was updated
      throw Exception('Could not find job document to update');
    } catch (e) {
      debugPrint('Error completing job: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error completing job: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show success message when job is completed
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Job marked as completed!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Refresh jobs from Firestore
  Future<void> _refreshJobs() async {
    await _loadJobsFromFirestore(_currentVehicleId);
  }

  // Handle back button press safely
  Future<bool> _handleBackPress() async {
    if (_isNavigatingBack) return true;

    setState(() {
      _isNavigatingBack = true;
    });

    // Navigate to the map page instead of just popping
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MapPage()),
    );

    return false; // Don't perform the default back operation
  }

  @override
  Widget build(BuildContext context) {
    // Separate jobs into pending and completed
    final pendingJobs = _history.where((job) => job.isPending).toList();
    final completedJobs = _history.where((job) => job.isCompleted).toList();

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'YOUR JOBS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Custom back navigation to prevent crashes
              if (!_isNavigatingBack) {
                setState(() {
                  _isNavigatingBack = true;
                });

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              }
            },
          ),
          actions: [
            // Add refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _refreshJobs,
              tooltip: 'Refresh Jobs',
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6D6BF8),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 70,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refreshJobs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D6BF8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
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
                            if (_currentVehicleId != null)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Vehicle ID: $_currentVehicleId',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refreshJobs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D6BF8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshJobs,
                        color: const Color(0xFF6D6BF8),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Fixed summary at the top
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: JobSummaryWidget(jobs: _history),
                              ),

                              // Vehicle ID indicator - only show in development
                              if (_currentVehicleId != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      'Vehicle ID: $_currentVehicleId',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ),
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
                                              onCompletePressed: () =>
                                                  _completeJob(
                                                      pendingJobs[index]
                                                          .historyId),
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
                                                  _showCompleted
                                                      ? 'Hide'
                                                      : 'Show',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14.0.sp,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _showCompleted =
                                                        !_showCompleted;
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
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
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (context, index) =>
                                                  CompletedJobCard(
                                                      job:
                                                          completedJobs[index]),
                                              childCount: completedJobs.length,
                                            ),
                                          ),
                                        ),
                                    ],

                                    // Empty state for when all jobs are completed
                                    if (pendingJobs.isEmpty &&
                                        completedJobs.isNotEmpty)
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
                      ),
      ),
    );
  }
}
