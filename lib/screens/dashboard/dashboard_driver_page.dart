import 'dart:convert';

import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/screens/dashboard/driver_history_page.dart';
import 'package:driveorbit_app/screens/qr_scan/qr_scan_page.dart';
import 'package:driveorbit_app/widgets/vehicle_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
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
                // Add Flexible wrapper
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
                      const TextSpan(
                        text: 'Chandeera!',
                        style: TextStyle(
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
              const CircleAvatar(
                backgroundImage: AssetImage('assets/chandeera.jpg'),
              ),
            ],
          )),
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
                  toolbarHeight: 75.h, // 70,
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
                          Colors.transparent, // Start with transparent
                          Colors.red, // Fade to red
                          Colors.red, // Stay red
                          Colors.transparent, // Fade back to transparent
                        ],
                        stops: [
                          0.0,
                          0.01,
                          (!_isExpanded) ? 0.7 : 0.9,
                          1.0
                        ], // Adjust stops for a smaller fade area
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
                /* SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ShaderMask(
                          shaderCallback: (Rect rect) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[Colors.transparent, Colors.red],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child:
                              VehicleDetails(entity: _filteredMessages[index]));
                    },
                    childCount: _isExpanded
                        ? _filteredMessages.length
                        : _filteredMessages.length > _initialVehicleCount
                            ? _initialVehicleCount
                            : _filteredMessages.length,
                  ),
                ), */
                if (_isExpanded)
                  SliverToBoxAdapter(
                    child: _messages.length > _initialVehicleCount
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
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
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                          color: Colors.white24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 13),
                                  ),
                                  child: Text(
                                    _isExpanded ? 'Show Less' : 'Show More',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                /* SliverToBoxAdapter(
                  child: _messages.length > _initialVehicleCount
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
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
                                    borderRadius: BorderRadius.circular(20),
                                    side:
                                        const BorderSide(color: Colors.white24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 13),
                                ),
                                child: Text(
                                  _isExpanded ? 'Show Less' : 'Show More',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
 */
              ],
            ),
          ),

          // Bottom Content (Fixed when not expanded)
          if (!_isExpanded)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(66),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  (_messages.length > _initialVehicleCount)
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
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
                                    borderRadius: BorderRadius.circular(20),
                                    side:
                                        const BorderSide(color: Colors.white24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 13),
                                ),
                                child: Text(
                                  _isExpanded ? 'Show Less' : 'Show More',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),

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
                  const SizedBox(height: 60), // Reduced Spacer

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
                  const SizedBox(height: 16),

                  // Adjusted QR code scanner button to bottom center
                  Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const QRScannerPage()),
                        );
                      },
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