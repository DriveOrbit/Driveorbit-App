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

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

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
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/truck1.png'),
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

                const Text(
                  'Maintenance Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

// First row of indicators
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    MaintenanceIndicator(
                      title: 'Engine Oil',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                    MaintenanceIndicator(
                      title: 'Coolant Level',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                    MaintenanceIndicator(
                      title: 'Brake Fluid',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Second row of indicators
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    MaintenanceIndicator(
                      title: 'Transmission Fluid',
                      status: 'Didn\'t check',
                      date: 'Please check it',
                      statusColor: Colors.red,
                    ),
                    MaintenanceIndicator(
                      title: 'Battery Health',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                    MaintenanceIndicator(
                      title: 'Tyre Pressure & Condition',
                      status: 'NEED TO CHECK',
                      date: '',
                      statusColor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Third row of indicators
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    MaintenanceIndicator(
                      title: 'Brakes Condition',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                    MaintenanceIndicator(
                      title: 'Lights & Signals',
                      status: 'Last check',
                      date: '08/12/2024',
                      statusColor: Colors.blue,
                    ),
                    MaintenanceIndicator(
                      title: 'Wiper Blades & Fluid',
                      status: 'Last check',
                      date: 'Last week',
                      statusColor: Colors.blue,
                    ),
                  ],
                ),
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
