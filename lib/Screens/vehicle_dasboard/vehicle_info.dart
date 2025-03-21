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
        SizedBox(width: 8),
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
              style: TextStyle(
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

  // Add this method to _VehicleInfoPageState class
  List<Map<String, dynamic>> getLowMaintenanceItems() {
    final maintenanceItems = widget.calculateMaintenanceStatus();
    final lowItems = <Map<String, dynamic>>[];

    maintenanceItems.forEach((key, item) {
      if (item.percentage < 25) {
        lowItems.add({
          'title': key,
          'icon': getMaintenanceIcon(key),
        });
      }
    });

    return lowItems;
  }

  IconData getMaintenanceIcon(String maintenanceType) {
    switch (maintenanceType) {
      case 'Engine Oil':
        return Icons.oil_barrel;
      case 'Coolant Level':
        return Icons.water_drop;
      case 'Brake Fluid':
        return Icons.report_problem;
      case 'Transmission Fluid':
        return Icons.settings;
      case 'Battery Health':
        return Icons.battery_alert;
      case 'Tyre Pressure & Condition':
        return Icons.tire_repair;
      case 'Brakes Condition':
        return Icons.do_not_step;
      case 'Lights & Signals':
        return Icons.highlight;
      case 'Wiper Blades & Fluid':
        return Icons.wash;
      default:
        return Icons.warning;
    }
  }

  Widget _buildToolItem({
    required IconData icon,
    required String title,
    required bool available,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double percentage,
    bool isWide = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
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
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: isWide ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              isWide
                  ? SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String warning, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 18,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            warning,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.5),
          size: 14,
        ),
      ],
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Vehicle Image with Overlay
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: AssetImage('assets/KDH.png'),
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
                          borderRadius: BorderRadius.only(
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
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

                // License Plate Style Vehicle Number
                // Replace the existing License Plate Style Vehicle Number section with this:
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
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
                    children: [
                      // Vehicle Model
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade900,
                              Colors.blue.shade800
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'TOYOTA KDH 201 SUPARIAL GL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // License Plate Number
                      // License Plate Style Vehicle Number
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade800,
                              Colors.grey.shade900,
                              Colors.grey.shade800,
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
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              decoration: BoxDecoration(
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
                                    'TOYOTA',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[400],
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'KDH 201 SUPARIAL GL',
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
                              margin: EdgeInsets.all(16),
                              padding: EdgeInsets.symmetric(
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SL',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'PF-9093',
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 3,
                                      fontFamily: 'RobotoMono',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
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
                      SizedBox(height: 24),

                      // Vehicle Metrics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Condition',
                              value: 'Good',
                              icon: Icons.check_circle,
                              color: Colors.green,
                              percentage: 85,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Fuel Efficiency',
                              value: '12.3 KM/L',
                              icon: Icons.local_gas_station,
                              color: Colors.amber,
                              percentage: 70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildMetricCard(
                        title: 'Recommended Distance',
                        value: '1022 KM',
                        icon: Icons.route,
                        color: Colors.blue,
                        percentage: 65,
                        isWide: true,
                      ),
                      SizedBox(height: 20),

                      // Warning Panel
                      // Replace the existing Warning Panel with this new design
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade900,
                              Colors.grey.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.warning_amber,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Attention Needed',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Regular warnings
                            if (getLowMaintenanceItems().isNotEmpty) ...[
                              ...getLowMaintenanceItems()
                                  .map((item) => Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: _buildWarningItem(
                                          'Maintenance Required: ${item['title']}',
                                          item['icon'],
                                        ),
                                      )),
                            ],
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: _buildWarningItem(
                                'Please Check Tyre Pressure and Condition',
                                Icons.tire_repair,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: _buildWarningItem(
                                'Fog Lights are not working',
                                Icons.highlight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Replace the existing Vehicle Info and Tools container with this new design
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle Information Card
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(20),
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
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.directions_car,
                                            color: Colors.blue, size: 24),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Vehicle Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildInfoItem(
                                              icon: Icons.category,
                                              label: 'Type',
                                              value: 'Van',
                                            ),
                                            SizedBox(height: 16),
                                            _buildInfoItem(
                                              icon: Icons.local_gas_station,
                                              label: 'Fuel Type',
                                              value: 'Petrol',
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
                                              value: 'Auto',
                                            ),
                                            SizedBox(height: 16),
                                            _buildInfoItem(
                                              icon: Icons.calendar_today,
                                              label: 'Model Year',
                                              value: '2024',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Available Tools Card
                            Container(
                              padding: EdgeInsets.all(20),
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
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.handyman,
                                            color: Colors.orange, size: 24),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Available Tools',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  _buildToolItem(
                                    icon: Icons.tire_repair,
                                    title: 'Spare Tyre & Toolkit',
                                    available: true,
                                  ),
                                  SizedBox(height: 12),
                                  _buildToolItem(
                                    icon: Icons.medical_services,
                                    title: 'Emergency Kit',
                                    available: true,
                                  ),
                                  SizedBox(height: 12),
                                  _buildToolItem(
                                    icon: Icons.warning,
                                    title: 'Warning Triangle',
                                    available: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Maintenance Status Header
                      Row(
                        children: [
                          Icon(Icons.build_circle,
                              color: Colors.blue, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Maintenance Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

// Calculate maintenance status
                      Builder(builder: (context) {
                        final maintenanceItems =
                            widget.calculateMaintenanceStatus();

                        return Column(
                          children: [
                            // First row of indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                MaintenanceIndicator(
                                  title: 'Engine Oil',
                                  status:
                                      maintenanceItems['Engine Oil']!.status,
                                  date: maintenanceItems['Engine Oil']!.date,
                                  statusColor:
                                      maintenanceItems['Engine Oil']!.color,
                                  percentage: maintenanceItems['Engine Oil']!
                                      .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Coolant Level',
                                  status:
                                      maintenanceItems['Coolant Level']!.status,
                                  date: maintenanceItems['Coolant Level']!.date,
                                  statusColor:
                                      maintenanceItems['Coolant Level']!.color,
                                  percentage: maintenanceItems['Coolant Level']!
                                      .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Brake Fluid',
                                  status:
                                      maintenanceItems['Brake Fluid']!.status,
                                  date: maintenanceItems['Brake Fluid']!.date,
                                  statusColor:
                                      maintenanceItems['Brake Fluid']!.color,
                                  percentage: maintenanceItems['Brake Fluid']!
                                      .percentage,
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
                                      maintenanceItems['Transmission Fluid']!
                                          .status,
                                  date: 'Please check it',
                                  statusColor:
                                      maintenanceItems['Transmission Fluid']!
                                          .color,
                                  percentage:
                                      maintenanceItems['Transmission Fluid']!
                                          .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Battery Health',
                                  status: maintenanceItems['Battery Health']!
                                      .status,
                                  date:
                                      maintenanceItems['Battery Health']!.date,
                                  statusColor:
                                      maintenanceItems['Battery Health']!.color,
                                  percentage:
                                      maintenanceItems['Battery Health']!
                                          .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Tyre Pressure & Condition',
                                  status: maintenanceItems[
                                          'Tyre Pressure & Condition']!
                                      .status,
                                  date: maintenanceItems[
                                          'Tyre Pressure & Condition']!
                                      .date,
                                  statusColor: maintenanceItems[
                                          'Tyre Pressure & Condition']!
                                      .color,
                                  percentage: maintenanceItems[
                                          'Tyre Pressure & Condition']!
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
                                  status: maintenanceItems['Brakes Condition']!
                                      .status,
                                  date: maintenanceItems['Brakes Condition']!
                                      .date,
                                  statusColor:
                                      maintenanceItems['Brakes Condition']!
                                          .color,
                                  percentage:
                                      maintenanceItems['Brakes Condition']!
                                          .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Lights & Signals',
                                  status: maintenanceItems['Lights & Signals']!
                                      .status,
                                  date: maintenanceItems['Lights & Signals']!
                                      .date,
                                  statusColor:
                                      maintenanceItems['Lights & Signals']!
                                          .color,
                                  percentage:
                                      maintenanceItems['Lights & Signals']!
                                          .percentage,
                                ),
                                MaintenanceIndicator(
                                  title: 'Wiper Blades & Fluid',
                                  status:
                                      maintenanceItems['Wiper Blades & Fluid']!
                                          .status,
                                  date:
                                      maintenanceItems['Wiper Blades & Fluid']!
                                          .date,
                                  statusColor:
                                      maintenanceItems['Wiper Blades & Fluid']!
                                          .color,
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

                      // Replace the Positioned widget with a Container
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(vertical: 20),
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
                                pageBuilder:
                                    (context, animation1, animation2) =>
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
