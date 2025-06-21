import 'package:driveorbit_app/Screens/profile/driver_profile.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleInfoPage extends StatefulWidget {
  final int? vehicleId;

  const VehicleInfoPage({super.key, this.vehicleId});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  String _firstName = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;
  final bool _hasUnreadNotifications = false;

  final VehicleService _vehicleService = VehicleService();
  VehicleDetailsEntity? _vehicleDetails;
  bool _isLoadingVehicle = true;
  String _errorMessage = '';
  
  // Variables for distance tracking
  double _currentTotalDistance = 0.0; // Store the current total distance
  bool _isExceedingRecommendedDistance = false; // Flag to indicate if exceeding recommended distance

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVehicleData();
    _loadCurrentDistance(); // Load current distance from SharedPreferences or Firestore
  }

  // New method to load current total distance
  Future<void> _loadCurrentDistance() async {
    try {
      // Try to get distance from shared preferences first
      final prefs = await SharedPreferences.getInstance();
      _currentTotalDistance = prefs.getDouble('total_distance_traveled') ?? 0.0;
      
      // If no data in SharedPreferences, try to get from current job in Firestore
      if (_currentTotalDistance == 0.0) {
        final currentJobId = prefs.getString('current_job_id');
        
        if (currentJobId != null && currentJobId.isNotEmpty) {
          final jobDoc = await FirebaseFirestore.instance
              .collection('jobs')
              .doc(currentJobId)
              .get();
              
          if (jobDoc.exists && jobDoc.data() != null) {
            final jobData = jobDoc.data()!;
            final distanceFromJob = jobData['totalDistanceTraveled'];
            
            if (distanceFromJob != null) {
              _currentTotalDistance = distanceFromJob is double ? 
                  distanceFromJob : double.tryParse(distanceFromJob.toString()) ?? 0.0;
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          // Check if exceeding recommended distance
          if (_vehicleDetails != null) {
            _isExceedingRecommendedDistance = _currentTotalDistance > _vehicleDetails!.recommendedDistance;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading current distance: $e');
    }
  }

  Future<void> _loadVehicleData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingVehicle = true;
      _errorMessage = '';
    });

    try {
      // First, try to load from vehicleId passed to the page
      if (widget.vehicleId != null) {
        final vehicleData =
            await _vehicleService.fetchVehicleById(widget.vehicleId!);
        if (vehicleData != null && mounted) {
          setState(() {
            _vehicleDetails = vehicleData;
            _isLoadingVehicle = false;
            _isExceedingRecommendedDistance = _currentTotalDistance > vehicleData.recommendedDistance;
          });
          return;
        }
      }

      // If no vehicleId or it failed, try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentJobId = prefs.getString('current_job_id');

      // If we have a current job, try to get its vehicle details
      if (currentJobId != null && currentJobId.isNotEmpty) {
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(currentJobId)
            .get();

        if (jobDoc.exists && jobDoc.data() != null) {
          final jobData = jobDoc.data()!;
          final vehicleId = jobData['vehicleId'];

          if (vehicleId != null) {
            // Try to convert to int if it's not already
            final vId = vehicleId is int
                ? vehicleId
                : int.tryParse(vehicleId.toString());

            if (vId != null) {
              final vehicleData = await _vehicleService.fetchVehicleById(vId);
              if (vehicleData != null && mounted) {
                setState(() {
                  _vehicleDetails = vehicleData;
                  _isLoadingVehicle = false;
                  _isExceedingRecommendedDistance = _currentTotalDistance > vehicleData.recommendedDistance;
                });
                return;
              }
            }
          }
        }
      }

      // If all else fails, load the first vehicle from Firestore
      final vehicles = await _vehicleService.fetchVehicles();
      if (vehicles.isNotEmpty && mounted) {
        setState(() {
          _vehicleDetails = vehicles.first;
          _isLoadingVehicle = false;
          _isExceedingRecommendedDistance = _currentTotalDistance > vehicles.first.recommendedDistance;
        });
      } else {
        throw Exception("No vehicles found");
      }
    } catch (e) {
      debugPrint('Error loading vehicle data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load vehicle data. Please try again.';
          _isLoadingVehicle = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();

      final cachedFirstName = prefs.getString('user_firstName') ?? '';
      final cachedProfilePic = prefs.getString('user_profilePicture') ?? '';

      if (cachedFirstName.isNotEmpty && mounted) {
        setState(() {
          _firstName = cachedFirstName;
          _profilePictureUrl = cachedProfilePic;
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final freshFirstName = userData['firstName']?.toString() ?? '';
      final freshProfilePic = userData['profilePicture']?.toString() ?? '';

      if (freshFirstName.isNotEmpty && mounted) {
        setState(() {
          _firstName = freshFirstName;
          if (freshProfilePic.isNotEmpty) {
            _profilePictureUrl = freshProfilePic;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ...existing helper methods and widgets...

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String title,
    required bool available,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: available
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: available ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: available
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              available ? 'Available' : 'Missing',
              style: TextStyle(
                color: available ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // Get color based on vehicle condition
  Color _getConditionColor(String? condition) {
    if (condition == null) return Colors.grey;

    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // New method to build distance progress bar
  Widget _buildDistanceProgressBar() {
    if (_vehicleDetails == null) {
      return const SizedBox.shrink();
    }
    
    final recommendedDistance = _vehicleDetails!.recommendedDistance.toDouble();
    double progressValue = recommendedDistance > 0 ? 
        (_currentTotalDistance / recommendedDistance).clamp(0.0, 1.5) : 0.0;
    
    Color progressColor;
    if (progressValue >= 1.0) {
      progressColor = Colors.red;
    } else if (progressValue >= 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_currentTotalDistance.toStringAsFixed(1)} / ${recommendedDistance.toInt()} KM',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isExceedingRecommendedDistance)
                    Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 18.sp,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Progress bar background
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              // Progress bar fill
              FractionallySizedBox(
                widthFactor: progressValue.clamp(0.0, 1.0),
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Warning message if exceeding recommended distance
          if (_isExceedingRecommendedDistance)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Vehicle has exceeded recommended distance. Maintenance is recommended.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverProfilePage(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${getGreeting()} ',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6D6BF8),
                          fontSize: 22.sp,
                        ),
                      ),
                      TextSpan(
                        text:
                            _firstName.isNotEmpty ? '$_firstName!' : 'Driver!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 9.w),
            _isLoading
                ? SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverProfilePage(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundImage: _profilePictureUrl.isNotEmpty
                              ? NetworkImage(_profilePictureUrl)
                                  as ImageProvider
                              : const AssetImage('assets/default_avatar.jpg'),
                          onBackgroundImageError: (_, __) {
                            setState(() {
                              _profilePictureUrl =
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_firstName)}&background=random';
                            });
                          },
                        ),
                        if (_hasUnreadNotifications)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingVehicle
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF6D6BF8)),
                    SizedBox(height: 20.h),
                    Text(
                      "Loading vehicle information...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    )
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60.sp, color: Colors.red),
                        SizedBox(height: 20.h),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton(
                          onPressed: _loadVehicleData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D6BF8),
                          ),
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Image with Overlay
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: _vehicleDetails!.vehicleImage
                                            .startsWith('assets/')
                                        ? AssetImage(
                                            _vehicleDetails?.vehicleImage ??
                                                'assets/KDH.png')
                                        : (_vehicleDetails!.vehicleImage
                                                    .startsWith('http')
                                                ? NetworkImage(_vehicleDetails!
                                                    .vehicleImage)
                                                : const AssetImage('assets/KDH.png'))
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _vehicleDetails?.vehicleStatus
                                                .toLowerCase() ==
                                            'available'
                                        ? Colors.green[700]
                                        : (_vehicleDetails?.vehicleStatus
                                                    .toLowerCase() ==
                                                'booked'
                                            ? Colors.amber[700]
                                            : Colors.red[700]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _vehicleDetails?.vehicleStatus
                                                      .toLowerCase() ==
                                                  'available'
                                              ? Icons.check_circle
                                              : (_vehicleDetails?.vehicleStatus
                                                          .toLowerCase() ==
                                                      'booked'
                                                  ? Icons.access_time
                                                  : Icons.cancel),
                                          color: Colors.white,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _vehicleDetails?.vehicleStatus ??
                                            'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Vehicle Details Section
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Vehicle Model
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black87, Colors.black54],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _vehicleDetails?.vehicleType
                                                .toUpperCase() ??
                                            'VEHICLE',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[400],
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _vehicleDetails?.vehicleModel ??
                                            'UNKNOWN MODEL',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // License Plate Number
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade900,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _vehicleDetails?.plateNumber
                                                  .substring(0, 2) ??
                                              'SL',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _vehicleDetails?.plateNumber
                                                .substring(2) ??
                                            'XXXXXX',
                                        style: TextStyle(
                                          fontSize: 28.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 3,
                                          fontFamily: 'RobotoMono',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.verified,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // New section for fuel consumption and recommended distance
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade900,
                                  Colors.grey.shade800
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isExceedingRecommendedDistance 
                                    ? Colors.red.withOpacity(0.3) 
                                    : Colors.blue.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isExceedingRecommendedDistance 
                                      ? Colors.red.withOpacity(0.1) 
                                      : Colors.blue.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.cyan.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.speed,
                                        color: Colors.cyan,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Vehicle Performance',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Fuel Consumption
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_gas_station,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Fuel Consumption:',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_vehicleDetails?.fuelConsumption ?? "N/A"} KM/L',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Recommended Distance with Progress Bar
                                Text(
                                  'Recommended Service Interval:',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_vehicleDetails?.recommendedDistance ?? 0} KM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                
                                // Custom distance progress bar
                                _buildDistanceProgressBar(),
                              ],
                            ),
                          ),

                          // Vehicle Information Card - Using real data
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade900,
                                  Colors.grey.shade800
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.directions_car,
                                          color: Colors.blue, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Vehicle Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildInfoItem(
                                            icon: Icons.category,
                                            label: 'Type',
                                            value:
                                                _vehicleDetails?.vehicleType ??
                                                    'Unknown',
                                          ),
                                          const SizedBox(height: 16),
                                          _buildInfoItem(
                                            icon: Icons.local_gas_station,
                                            label: 'Fuel Type',
                                            value: _vehicleDetails?.fuelType ??
                                                'Unknown',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildInfoItem(
                                            icon: Icons.settings,
                                            label: 'Transmission',
                                            value:
                                                _vehicleDetails?.gearSystem ??
                                                    'Unknown',
                                          ),
                                          const SizedBox(height: 16),
                                          _buildInfoItem(
                                            icon: Icons.speed,
                                            label: 'Condition',
                                            value: _vehicleDetails?.condition ??
                                                'Unknown',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Available Tools Card - Simplified
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade900,
                                  Colors.grey.shade800
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.handyman,
                                          color: Colors.orange, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Available Tools',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildToolItem(
                                  icon: Icons.tire_repair,
                                  title: 'Spare Tyre & Toolkit',
                                  available:
                                      _vehicleDetails?.hasSpareTools ?? false,
                                ),
                                const SizedBox(height: 12),
                                _buildToolItem(
                                  icon: Icons.medical_services,
                                  title: 'Emergency Kit',
                                  available:
                                      _vehicleDetails?.hasEmergencyKit ?? false,
                                ),
                                const SizedBox(height: 12),
                                _buildToolItem(
                                  icon: Icons.warning,
                                  title: 'Warning Triangle',
                                  available: true,
                                ),
                              ],
                            ),
                          ),

                          // Back button - replaced with a simple button
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Return to Dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D6BF8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
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
