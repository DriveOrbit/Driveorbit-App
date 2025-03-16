import 'dart:convert';

import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/screens/dashboard/driver_history_page.dart';
import 'package:driveorbit_app/screens/qr_scan/qr_scan_page.dart';
import 'package:driveorbit_app/widgets/vehicle_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardDriverPage extends StatefulWidget {
  const DashboardDriverPage({super.key});

  @override
  State<DashboardDriverPage> createState() => _DashboardDriverPageState();
}

class _DashboardDriverPageState extends State<DashboardDriverPage> {
  List<VehicleDetailsEntity> _messages = [];
  List<VehicleDetailsEntity> _filteredMessages = [];
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _isExpanded = false;
  final int _initialVehicleCount = 4;
  String _driverStatus = 'Active';
  final ScrollController _scrollController = ScrollController();

  // User data
  String _firstName = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVehicleDetails();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('user_firstName') ?? 'User';
      _profilePictureUrl = prefs.getString('user_profilePicture') ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleDetails() async {
    final response =
        await rootBundle.loadString('assets/mock_vehicledetails.json');
    final List<dynamic> decodedList = jsonDecode(response);
    final List<VehicleDetailsEntity> vehicleDetails =
        decodedList.map((item) => VehicleDetailsEntity.fromJson(item)).toList();

    setState(() {
      _messages = vehicleDetails;
      _filteredMessages = vehicleDetails;
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Booked':
        return Colors.orange;
      case 'Not available':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  Color _getStatusColorByText(String statusText) {
    switch (statusText) {
      case 'Active':
        return Colors.green;
      case 'Taking a break':
        return Colors.orange;
      case 'Unavailable':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMessages = _messages.where((vehicle) {
        final matchesSearch = vehicle.vehicleModel
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            vehicle.vehicleNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesType = _selectedTypeFilter == 'All' ||
            vehicle.vehicleType == _selectedTypeFilter;

        final matchesStatus = _selectedStatusFilter == 'All' ||
            vehicle.vehicleStatus == _selectedStatusFilter;

        return matchesSearch && matchesType && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${getGreeting()}, ',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6D6BF8),
                        fontSize: 22.sp,
                      ),
                    ),
                    TextSpan(
                      text: '$_firstName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : CircleAvatar(
                    backgroundImage: _profilePictureUrl.isNotEmpty
                        ? NetworkImage(_profilePictureUrl) as ImageProvider
                        : const AssetImage('assets/chandeera.jpg'),
                    onBackgroundImageError: (_, __) {
                      // Fallback in case the network image fails to load
                      setState(() {
                        _profilePictureUrl = '';
                      });
                    },
                  ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Main Scrollable Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.black,
                  toolbarHeight: 75.h,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search vehicles...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedTypeFilter,
                              items: [
                                'All',
                                'Car',
                                'Van',
                                'SUV',
                                'Truck',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedTypeFilter = value!;
                                  _applyFilters();
                                });
                              },
                              dropdownColor: Colors.grey[900],
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              underline: Container(),
                              isExpanded: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedStatusFilter,
                              items: [
                                'All',
                                'Available',
                                'Booked',
                                'Not available',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      if (value != 'All')
                                        Container(
                                          width: 16,
                                          height: 16,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(value),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (value == 'All')
                                        const Text(
                                          'All',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatusFilter = value!;
                                  _applyFilters();
                                });
                              },
                              dropdownColor: Colors.grey[900],
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              underline: Container(),
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ShaderMask(
                    shaderCallback: (Rect rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const <Color>[
                          Colors.transparent,
                          Colors.red,
                          Colors.red,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.01, (!_isExpanded) ? 0.7 : 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return VehicleDetails(entity: _filteredMessages[index]);
                      },
                      itemCount: _isExpanded
                          ? _filteredMessages.length
                          : _filteredMessages.length > _initialVehicleCount
                              ? _initialVehicleCount
                              : _filteredMessages.length,
                    ),
                  ),
                ),
                if (_isExpanded)
                  SliverToBoxAdapter(
                    child: _messages.length > _initialVehicleCount
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: ScreenUtil().screenHeight * 0.05,
                                  width: ScreenUtil().screenWidth * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                        if (_isExpanded) {
                                          _scrollController.animateTo(
                                            0,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[900],
                                      foregroundColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                        side: const BorderSide(
                                            color: Colors.white24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 7, horizontal: 16),
                                    ),
                                    child: Text(
                                      _isExpanded ? 'Show Less' : 'Show More',
                                      style: TextStyle(fontSize: 15.sp),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),

          // Bottom Content (Fixed when not expanded)
          if (!_isExpanded)
            Container(
              color: Colors.black,
              padding: EdgeInsets.only(
                // Adjusted padding
                left: 16.w,
                right: 16.w,
                bottom: 52.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_messages.length > _initialVehicleCount)
                    Padding(
                      padding: EdgeInsets.only(
                        // Adjusted button padding
                        top: 4.h, // Reduced top spacing
                        bottom: 40.h,
                        left: 8.w,
                        right: 10.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: ScreenUtil().screenHeight * 0.05,
                            width: ScreenUtil().screenWidth * 0.3,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                  if (_isExpanded) {
                                    _scrollController.animateTo(
                                      0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  side: const BorderSide(color: Colors.white24),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.h, vertical: 12.w),
                              ),
                              child: Text(
                                _isExpanded ? 'Show Less' : 'Show More',
                                style: TextStyle(fontSize: 15.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DriverHistoryPage()),
                        );
                      },
                      icon: const Icon(Icons.history, size: 26),
                      label: const Text(
                        'View Your Driving History',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                          side: const BorderSide(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Adjusted spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Driver Status',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        initialValue: _driverStatus,
                        onSelected: (String item) {
                          setState(() {
                            _driverStatus = item;
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Taking a break',
                            child: Text('Taking a break'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Unavailable',
                            child: Text('Unavailable'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColorByText(_driverStatus),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _driverStatus,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      child: IconButton(
                        icon: Image.asset(
                          'assets/icons/qr_scanner.png',
                          width: 66.w, // Responsive width
                          height: 66.h, // Responsive height
                          color: Colors.white, // Optional: tint color
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ScanCodePage()),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
