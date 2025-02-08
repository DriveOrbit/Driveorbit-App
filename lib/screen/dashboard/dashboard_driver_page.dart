import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/widgets/vehicle_details.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardDriverPage extends StatefulWidget {
  const DashboardDriverPage({super.key});

  @override
  State<DashboardDriverPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<DashboardDriverPage> {
  List<VehicleDetailsEntity> _messages = [];
  List<VehicleDetailsEntity> _filteredMessages = [];
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';
  String _selectedStatusFilter = 'All';

  _loadVehicleDetails() async {
    final response =
        await rootBundle.loadString('assets/mock_vehicledetails.json');

    final List<dynamic> decodedList = jsonDecode(response) as List<dynamic>;
    final List<VehicleDetailsEntity> vehicleDetails = decodedList.map((item) {
      return VehicleDetailsEntity.fromJson(item as Map<String, dynamic>);
    }).toList();

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
  void initState() {
    _loadVehicleDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: '${getGreeting()}, ',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6D6BF8),
                      fontSize: 20.0,
                    ),
                  ),
                  const TextSpan(
                    text: 'Chandeera!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/chandeera.jpg'),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search vehicles...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
              ),
            ),

            // Filter Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: [
                  // Vehicle Type Filter
                  Expanded(
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
                            style: TextStyle(color: Colors.white),
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
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      underline: Container(),
                      isExpanded: true,
                    ),
                  ),

                  const SizedBox(width: 150),

                  // Vehicle Status Filter
                  Expanded(
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
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.white),
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
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      underline: Container(),
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
            ),

            // Vehicle List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                return VehicleDetails(entity: _filteredMessages[index]);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
