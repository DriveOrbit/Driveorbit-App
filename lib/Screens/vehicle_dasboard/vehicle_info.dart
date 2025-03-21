import 'package:driveorbit_app/Screens/profile/driver_profile.dart';
import 'package:driveorbit_app/Screens/vehicle_dasboard/map_page.dart';
import 'package:driveorbit_app/widgets/BulletPoint_%20ToolItem.dart';
import 'package:driveorbit_app/widgets/maintenance_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add this class to store maintenance item data
class MaintenanceItem {
  final String title;
  final String status;
  final String date;
  final double percentage;
  final Color color;

  MaintenanceItem({
    required this.title,
    required this.status,
    required this.date,
    required this.percentage,
    required this.color,
  });
}

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

  Map<String, MaintenanceItem> calculateMaintenanceStatus() {
    // Define recommended days between maintenance for each item
    final recommendedIntervals = {
      'Engine Oil': 90, // 3 months
      'Coolant Level': 180, // 6 months
      'Brake Fluid': 365, // 1 year
      'Transmission Fluid': 730, // 2 years
      'Battery Health': 180, // 6 months
      'Tyre Pressure & Condition': 30, // 1 month
      'Brakes Condition': 180, // 6 months
      'Lights & Signals': 90, // 3 months
      'Wiper Blades & Fluid': 90, // 3 months
    };

    // Sample last check dates (in a real app, these would come from your database)
    final lastCheckDates = {
      'Engine Oil': '08/12/2024',
      'Coolant Level': '08/12/2024',
      'Brake Fluid': '08/12/2024',
      'Transmission Fluid': '',
      'Battery Health': '08/12/2024',
      'Tyre Pressure & Condition': '',
      'Brakes Condition': '08/12/2024',
      'Lights & Signals': '08/12/2024',
      'Wiper Blades & Fluid': 'Last week',
    };

    // Calculate status for each maintenance item
    final result = <String, MaintenanceItem>{};

    lastCheckDates.forEach((key, date) {
      final days = recommendedIntervals[key] ?? 90;
      final percentage = MaintenanceIndicator.calculatePercentage(date, days);
      final color = MaintenanceIndicator.getColorForPercentage(percentage);

      String status;
      if (percentage >= 75) {
        status = 'Good';
      } else if (percentage >= 25) {
        status = 'Check Soon';
      } else {
        status = 'Check Now';
      }

      result[key] = MaintenanceItem(
        title: key,
        status: status,
        date: date,
        percentage: percentage,
        color: color,
      );
    });

    return result;
  }

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  String _firstName = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add after the header in the Column children
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/KDH.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle title
                const Center(
                  child: Text(
                    'TOYOTA KDH 201 SUPARIAL GL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Vehicle number
                const Center(
                  child: Text(
                    'PF-9093',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle condition
                Row(
                  children: [
                    const Text(
                      'Vehicle overall condition is : ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Good',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fuel consumption
                Row(
                  children: [
                    const Text(
                      'Average Fuel consumption : ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '12.3 KM/L',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recommended destination
                Row(
                  children: [
                    const Text(
                      'Recommended Destination : ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '1022 KM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Warning messages
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '-Please Check Tyre Pressure and Condition',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[400],
                      ),
                    ),
                    Text(
                      '-Fog Lights are not working',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Add after warnings
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Vehicle Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          BulletPoint(text: 'Vehicle Type: van'),
                          BulletPoint(text: 'Fuel Type: Petrol'),
                          BulletPoint(text: 'Gear System: Auto'),
                        ],
                      ),
                    ),

                    // Available Tools
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Available Tools',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ToolItem(
                              text: 'Spare Tyre & Toolkit', available: true),
                          ToolItem(text: 'Emergency Kit', available: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Replace the maintenance indicators section with this code
                const Text(
                  'Maintenance Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

// Calculate maintenance status
                Builder(builder: (context) {
                  final maintenanceItems = widget.calculateMaintenanceStatus();

                  return Column(
                    children: [
                      // First row of indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MaintenanceIndicator(
                            title: 'Engine Oil',
                            status: maintenanceItems['Engine Oil']!.status,
                            date: maintenanceItems['Engine Oil']!.date,
                            statusColor: maintenanceItems['Engine Oil']!.color,
                            percentage:
                                maintenanceItems['Engine Oil']!.percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Coolant Level',
                            status: maintenanceItems['Coolant Level']!.status,
                            date: maintenanceItems['Coolant Level']!.date,
                            statusColor:
                                maintenanceItems['Coolant Level']!.color,
                            percentage:
                                maintenanceItems['Coolant Level']!.percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Brake Fluid',
                            status: maintenanceItems['Brake Fluid']!.status,
                            date: maintenanceItems['Brake Fluid']!.date,
                            statusColor: maintenanceItems['Brake Fluid']!.color,
                            percentage:
                                maintenanceItems['Brake Fluid']!.percentage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Second row of indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MaintenanceIndicator(
                            title: 'Transmission Fluid',
                            status:
                                maintenanceItems['Transmission Fluid']!.status,
                            date: 'Please check it',
                            statusColor:
                                maintenanceItems['Transmission Fluid']!.color,
                            percentage: maintenanceItems['Transmission Fluid']!
                                .percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Battery Health',
                            status: maintenanceItems['Battery Health']!.status,
                            date: maintenanceItems['Battery Health']!.date,
                            statusColor:
                                maintenanceItems['Battery Health']!.color,
                            percentage:
                                maintenanceItems['Battery Health']!.percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Tyre Pressure & Condition',
                            status:
                                maintenanceItems['Tyre Pressure & Condition']!
                                    .status,
                            date: maintenanceItems['Tyre Pressure & Condition']!
                                .date,
                            statusColor:
                                maintenanceItems['Tyre Pressure & Condition']!
                                    .color,
                            percentage:
                                maintenanceItems['Tyre Pressure & Condition']!
                                    .percentage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Third row of indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MaintenanceIndicator(
                            title: 'Brakes Condition',
                            status:
                                maintenanceItems['Brakes Condition']!.status,
                            date: maintenanceItems['Brakes Condition']!.date,
                            statusColor:
                                maintenanceItems['Brakes Condition']!.color,
                            percentage: maintenanceItems['Brakes Condition']!
                                .percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Lights & Signals',
                            status:
                                maintenanceItems['Lights & Signals']!.status,
                            date: maintenanceItems['Lights & Signals']!.date,
                            statusColor:
                                maintenanceItems['Lights & Signals']!.color,
                            percentage: maintenanceItems['Lights & Signals']!
                                .percentage,
                          ),
                          MaintenanceIndicator(
                            title: 'Wiper Blades & Fluid',
                            status: maintenanceItems['Wiper Blades & Fluid']!
                                .status,
                            date:
                                maintenanceItems['Wiper Blades & Fluid']!.date,
                            statusColor:
                                maintenanceItems['Wiper Blades & Fluid']!.color,
                            percentage:
                                maintenanceItems['Wiper Blades & Fluid']!
                                    .percentage,
                          ),
                        ],
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 20),

                Positioned(
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      child: IconButton(
                        iconSize: 66,
                        padding: EdgeInsets.zero,
                        icon: Image.asset(
                          'assets/icons/Nav-close.png',
                          width: 55,
                          height: 60,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) =>
                                  const MapPage(),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
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
