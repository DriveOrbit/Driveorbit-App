import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:driveorbit_app/services/job_history_service.dart';
import 'package:driveorbit_app/widgets/completed_job_card.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage>
    with SingleTickerProviderStateMixin {
  final JobHistoryService _jobHistoryService = JobHistoryService();

  List<JobDetailsEntity> _jobHistory = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Filtering and sorting
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'completedAt';
  bool _sortDescending = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Stats variables
  int _totalJobs = 0;
  double _totalDistance = 0;
  int _totalDuration = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadJobHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final jobHistory = await _jobHistoryService.fetchDriverJobHistory(
        startDate: _startDate,
        endDate: _endDate,
        sortBy: _sortBy,
        descending: _sortDescending,
      );

      if (mounted) {
        // Calculate stats
        _calculateStats(jobHistory);

        setState(() {
          _jobHistory = jobHistory;
          _isLoading = false;
          _hasError = false;
        });

        // Start animation
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('❌ Error in _loadJobHistory: $e');
      if (mounted) {
        setState(() {
          _hasError = true;

          // Customize the error message based on error type
          if (e is FirebaseException &&
              e.code == 'failed-precondition' &&
              e.message != null &&
              e.message!.contains('requires an index')) {
            _errorMessage = JobHistoryService.getIndexRequirementsMessage();
          } else {
            _errorMessage = 'Could not load job history: ${e.toString()}';
          }

          _isLoading = false;
        });
      }
    }
  }

  void _calculateStats(List<JobDetailsEntity> jobs) {
    _totalJobs = jobs.length;
    _totalDistance = 0;
    _totalDuration = 0;

    for (var job in jobs) {
      _totalDistance += job.distance.toDouble();
      _totalDuration += job.duration;
    }
  }

  void _showFilterDialog() {
    // Temporary date holders
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: const Color(0xFF6D6BF8),
                  size: 24.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'Filter Job History',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Title
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: const Color(0xFF6D6BF8),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Date Range',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Start date selector with enhanced design
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: tempStartDate != null
                          ? const Color(0xFF6D6BF8)
                          : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF6D6BF8),
                                onPrimary: Colors.white,
                                surface: Color(0xFF303030),
                                onSurface: Colors.white,
                              ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setDialogState(() {
                          tempStartDate = picked;
                        });
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[400],
                            size: 18.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Start Date:',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tempStartDate != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(tempStartDate!)
                                : 'Select Date',
                            style: GoogleFonts.poppins(
                              color: tempStartDate != null
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: tempStartDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // End date selector with enhanced design
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: tempEndDate != null
                          ? const Color(0xFF6D6BF8)
                          : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF6D6BF8),
                                onPrimary: Colors.white,
                                surface: Color(0xFF303030),
                                onSurface: Colors.white,
                              ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setDialogState(() {
                          tempEndDate = picked;
                        });
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[400],
                            size: 18.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'End Date:',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tempEndDate != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(tempEndDate!)
                                : 'Select Date',
                            style: GoogleFonts.poppins(
                              color: tempEndDate != null
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: tempEndDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Clear dates option
                if (tempStartDate != null || tempEndDate != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempStartDate = null;
                          tempEndDate = null;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.clear_all,
                            color: Colors.red[300],
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Clear All Dates',
                            style: GoogleFonts.poppins(
                              color: Colors.red[300],
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              // Cancel button with transparent background
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),

              // Apply button with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D6BF8), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  ),
                  onPressed: () {
                    Navigator.pop(context);

                    setState(() {
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                    });

                    _loadJobHistory();
                  },
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.sort,
              color: const Color(0xFF6D6BF8),
              size: 24.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              'Sort Jobs',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sort options with enhanced styling
            _buildSortOption(
              icon: Icons.calendar_today,
              title: 'Completion Date',
              value: 'completedAt',
            ),

            _buildSortOption(
              icon: Icons.straighten,
              title: 'Distance',
              value: 'tripDistance',
            ),

            _buildSortOption(
              icon: Icons.timer,
              title: 'Duration',
              value: 'tripDurationMinutes',
            ),

            Divider(color: Colors.grey[700], height: 32.h),

            // Order toggle with animation
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF6D6BF8), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: const Color(0xFF6D6BF8),
                    size: 20.sp,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      _sortDescending ? 'Newest First' : 'Oldest First',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _sortDescending,
                    onChanged: (value) {
                      Navigator.pop(context);
                      setState(() {
                        _sortDescending = value;
                      });
                      _loadJobHistory();
                    },
                    activeColor: const Color(0xFF6D6BF8),
                    activeTrackColor: const Color(0xFF6D6BF8).withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        // No explicit actions - click outside to dismiss
      ),
    );
  }

  // Helper method to build sort option item
  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isSelected = _sortBy == value;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6D6BF8).withOpacity(0.2)
            : Colors.grey[850],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? const Color(0xFF6D6BF8) : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _sortBy = value;
          });
          _loadJobHistory();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6D6BF8).withOpacity(0.3)
                      : Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                      isSelected ? const Color(0xFF6D6BF8) : Colors.grey[400],
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF6D6BF8),
                  size: 20.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        title: Text(
          'Driving History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          // Filter button with notification dot
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 26.sp,
                ),
                onPressed: _showFilterDialog,
                tooltip: 'Filter',
              ),
              if (_hasDateFilter())
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6D6BF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Sort button
          IconButton(
            icon: Icon(
              Icons.sort,
              color: Colors.white,
              size: 26.sp,
            ),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    // Show loading indicator
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced loading animation with gradient
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D6BF8).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF6D6BF8)),
                strokeWidth: 4.w,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Loading your driving history...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please wait a moment',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    // Show error message
    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64.sp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
              Text(
                'Something Went Wrong',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage.contains('Firebase index')
                      ? JobHistoryService.getIndexRequirementsMessage()
                      : _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              if (_errorMessage.contains('Firebase index'))
                Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Limited Mode Active',
                              style: GoogleFonts.poppins(
                                color: Colors.blue,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Some filtering and sorting features are limited until database updates are complete.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade200,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _loadJobHistory,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D6BF8),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (_jobHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty illustration with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.grey[500],
                        size: 80.sp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              Text(
                'No Driving History Yet',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Text(
                  _hasDateFilter()
                      ? 'No jobs found in the selected date range. Try adjusting your filters.'
                      : 'You haven\'t completed any jobs yet. Your driving history will appear here once you complete jobs.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 15.sp,
                    height: 1.5,
                  ),
                ),
              ),
              if (_hasDateFilter()) ...[
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadJobHistory();
                  },
                  icon: const Icon(Icons.filter_list_off),
                  label: Text(
                    'Clear Filters',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D6BF8),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Show job history with statistics
    return Column(
      children: [
        // Show statistics card if we have jobs
        if (_jobHistory.isNotEmpty)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildStatsCard(),
          ),

        // Date filter indicator if active
        if (_hasDateFilter())
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D6BF8).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFF6D6BF8), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range,
                    color: Color(0xFF6D6BF8),
                    size: 18,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    _formatDateFilterText(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadJobHistory();
                    },
                    borderRadius: BorderRadius.circular(15.r),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Job history list with animations
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadJobHistory,
            backgroundColor: Colors.grey[900],
            color: const Color(0xFF6D6BF8),
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _jobHistory.length,
              itemBuilder: (context, index) {
                final job = _jobHistory[index];

                // Add staggered animation effect to list items
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final start = index * 0.1;
                    final end = start + 0.4;
                    final animationValue = Interval(
                      start.clamp(0.0, 1.0),
                      end.clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ).transform(_animationController.value);

                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                              start.clamp(0.0, 1.0), end.clamp(0.0, 1.0)),
                        ),
                      ),
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1.0 - animationValue)),
                        child: child,
                      ),
                    );
                  },
                  child: CompletedJobCard(job: job),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Build statistics card
  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6D6BF8).withOpacity(0.9),
            const Color(0xFF5856D6).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D6BF8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stats title
          Text(
            'Driving Performance',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Stats indicators in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatIndicator(
                icon: Icons.my_location,
                value: _totalJobs.toString(),
                label: 'Total Jobs',
              ),
              _buildStatIndicator(
                icon: Icons.straighten,
                value: '${_totalDistance.toStringAsFixed(1)} km',
                label: 'Distance',
              ),
              _buildStatIndicator(
                icon: Icons.timer,
                value: '$_totalDuration min',
                label: 'Duration',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build stat indicator widget
  Widget _buildStatIndicator({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  bool _hasDateFilter() {
    return _startDate != null || _endDate != null;
  }

  String _formatDateFilterText() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${DateFormat('MMM d').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${DateFormat('MMM d').format(_endDate!)}';
    }
    return '';
  }
}
