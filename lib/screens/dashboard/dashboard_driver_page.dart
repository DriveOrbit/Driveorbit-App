import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driveorbit_app/models/notification_model.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/screens/dashboard/driver_history_page.dart';
import 'package:driveorbit_app/screens/profile/driver_profile.dart'; // Add this import
import 'package:driveorbit_app/screens/qr_scan/qr_scan_page.dart';
import 'package:driveorbit_app/services/notification_service.dart';
import 'package:driveorbit_app/widgets/notification_drawer.dart';
import 'package:driveorbit_app/widgets/vehicle_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driveorbit_app/widgets/draggable_notification_circle.dart';

class DashboardDriverPage extends StatefulWidget {
  const DashboardDriverPage({super.key});

  @override
  State<DashboardDriverPage> createState() => _DashboardDriverPageState();
}

class _DashboardDriverPageState extends State<DashboardDriverPage>
    with TickerProviderStateMixin {
  List<VehicleDetailsEntity> _messages = [];
  List<VehicleDetailsEntity> _filteredMessages = [];
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _isExpanded = false;
  final int _initialVehicleCount = 4;
  String _driverStatus = 'Active';
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;

  // User data
  String _firstName = ''; // Add this line to define the variable
  String _profilePictureUrl = '';
  bool _isLoading = true;

  // Notification related variables
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<NotificationModel> _notifications = [];
  bool _hasUnreadNotifications = false;
  final NotificationService _notificationService = NotificationService();

  // Add animation controllers for notification hint
  AnimationController? _notificationHintController;
  bool _hasShownNotificationTutorial = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVehicleDetails();
    _loadNotifications();
    // Set default status to All instead of Available
    _selectedStatusFilter = 'All';

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    // Initialize notification hint animation controller
    _notificationHintController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Check if we've shown the tutorial before
    _checkNotificationTutorial();
  }

  Future<void> _checkNotificationTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownNotificationTutorial =
        prefs.getBool('has_shown_notification_tutorial') ?? false;

    // Show tutorial if it's first time
    if (!_hasShownNotificationTutorial) {
      // Wait for the UI to build first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotificationTutorial();
      });
    }
  }

  void _showNotificationTutorial() {
    // Start animating the notification hint
    _notificationHintController!.repeat(reverse: true);

    // Show tutorial overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_right, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Swipe right from the left edge to view notifications',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF6D6BF8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          action: SnackBarAction(
            label: 'GOT IT',
            textColor: Colors.white,
            onPressed: () async {
              // Stop the hint animation
              _notificationHintController?.stop();

              // Mark as shown
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_shown_notification_tutorial', true);
              _hasShownNotificationTutorial = true;

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });

    // After 15 seconds, automatically dismiss the tutorial
    Future.delayed(const Duration(seconds: 15), () async {
      if (mounted && _notificationHintController?.isAnimating == true) {
        _notificationHintController?.stop();

        // Mark as shown
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_shown_notification_tutorial', true);
        _hasShownNotificationTutorial = true;
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _animationController?.dispose();
    _notificationHintController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);
      debugPrint('🔄 Loading user data from SharedPreferences');

      final prefs = await SharedPreferences.getInstance();

      // Load cached user data
      final cachedFirstName = prefs.getString('user_firstName') ?? '';
      final cachedProfilePic = prefs.getString('user_profilePicture') ?? '';

      // Set cached values first for immediate display
      if (cachedFirstName.isNotEmpty && mounted) {
        setState(() {
          _firstName = cachedFirstName;
          _profilePictureUrl = cachedProfilePic;
        });
      }

      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('🚫 No authenticated user. Using cached data only.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        _showErrorSnackbar(
            'Driver profile not found. Please contact administrator.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final freshFirstName = userData['firstName']?.toString() ?? '';
      final freshLastName = userData['lastName']?.toString() ?? '';
      final freshProfilePic = userData['profilePicture']?.toString() ?? '';

      if (freshFirstName.isNotEmpty && mounted) {
        setState(() {
          if (freshProfilePic.isNotEmpty) {
            _profilePictureUrl = freshProfilePic;
          }
        });

        // Cache user data
        await prefs.setString('user_firstName', freshFirstName);
        await prefs.setString('user_lastName', freshLastName);
        if (freshProfilePic.isNotEmpty) {
          await prefs.setString('user_profilePicture', freshProfilePic);
        }
      }
    } on FirebaseException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Error in _loadUserData: $e');
      _showErrorSnackbar('Failed to load user data');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    _notifications = await _notificationService.loadSampleNotifications();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = _notificationService.hasUnreadNotifications();
      });
    }
  }

  void _markAsRead(String id) {
    _notificationService.markAsRead(id);
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = _notificationService.hasUnreadNotifications();
      });
    }
  }

  void _markAllAsRead() {
    _notificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = false;
      });
    }
  }

  void _handleFirebaseError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      _showErrorSnackbar(
          'Permission denied accessing driver data. Please check your account permissions.');
    } else {
      _showErrorSnackbar('Error loading driver data: ${e.message}');
    }
    debugPrint('❌ Firebase error: ${e.code} - ${e.message}');
  }

  /// Shows an error message in a snackbar
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Future<void> _loadVehicleDetails() async {
    try {
      final response =
          await rootBundle.loadString('assets/mock_vehicledetails.json');
      final List<dynamic> decodedList = jsonDecode(response);
      final List<VehicleDetailsEntity> vehicleDetails = decodedList
          .map((item) => VehicleDetailsEntity.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _messages = vehicleDetails;
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicle details: $e');
      _showErrorSnackbar('Failed to load vehicle data');
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'active':
        return Colors.green;
      case 'booked':
      case 'taking a break':
        return Colors.orange;
      case 'not available':
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  void _updateSearchQuery(String query) {
    // Cancel any previous timer
    _searchDebounceTimer?.cancel();

    // Set a new timer
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _applyFilters();
        });
      }
    });
  }

  void _applyFilters() {
    if (!mounted) return;

    setState(() {
      _filteredMessages = _messages.where((vehicle) {
        final matchesSearch = _searchQuery.isEmpty ||
            vehicle.vehicleModel
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

  // Get count of unread notifications
  int get _unreadNotificationCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  // UI Components
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          Expanded(
            flex: 6, // Increase search bar flex from 5 to 6
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search vehicles...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _updateSearchQuery,
            ),
          ),
          const SizedBox(width: 10),
          _buildTypeFilterDropdown(),
          const SizedBox(width: 10),
          _buildStatusFilterToggle(),
        ],
      ),
    );
  }

  Widget _buildTypeFilterDropdown() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          value: _selectedTypeFilter,
          items: const [
            DropdownMenuItem(
                value: 'All',
                child: Text('All', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(
                value: 'Car',
                child: Text('Car', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(
                value: 'Van',
                child: Text('Van', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(
                value: 'SUV',
                child: Text('SUV', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(
                value: 'Truck',
                child: Text('Truck', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTypeFilter = value;
                _applyFilters();
              });
            }
          },
          dropdownColor: Colors.grey[900],
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          underline: Container(),
          isExpanded: true,
        ),
      ),
    );
  }

  // Modified status filter toggle to include "All" in the cycling sequence
  Widget _buildStatusFilterToggle() {
    return Expanded(
      flex: 1, // Revert back to flex 1
      child: InkWell(
        onTap: () {
          setState(() {
            // Cycle through filter statuses: All -> Available -> Booked -> Not available -> All
            switch (_selectedStatusFilter) {
              case 'All':
                _selectedStatusFilter = 'Available';
                break;
              case 'Available':
                _selectedStatusFilter = 'Booked';
                break;
              case 'Booked':
                _selectedStatusFilter = 'Not available';
                break;
              case 'Not available':
                _selectedStatusFilter = 'All';
                break;
              default:
                _selectedStatusFilter = 'All';
            }
            _applyFilters();
          });
        },
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _selectedStatusFilter == 'All'
                  ? Colors.white
                  : _getStatusColor(_selectedStatusFilter),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return Container(
      height: ScreenUtil().screenHeight * 0.05,
      width: ScreenUtil().screenWidth * 0.3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[850]!, Colors.grey[900]!, Colors.black],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
            if (_isExpanded) {
              _animationController?.forward();
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              _animationController?.reverse();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'Show Less' : 'Show More',
              style: TextStyle(fontSize: 15.sp),
            ),
            AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _isExpanded ? 3.14159 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggleButton() {
    return InkWell(
      onTap: () {
        _showStatusSelectionPopup();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(_driverStatus),
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              _driverStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showStatusSelectionPopup() {
    // Define the status options with their colors
    final statusOptions = [
      {'status': 'Active', 'color': Colors.green},
      {'status': 'Taking a break', 'color': Colors.orange},
      {'status': 'Unavailable', 'color': Colors.red},
    ];

    // Find initial selected index
    int initialSelectedIndex = 0;
    for (int i = 0; i < statusOptions.length; i++) {
      if (statusOptions[i]['status'] == _driverStatus) {
        initialSelectedIndex = i;
        break;
      }
    }

    // Create a new status selection controller
    ValueNotifier<int> selectedIndexNotifier =
        ValueNotifier(initialSelectedIndex);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: GestureDetector(
              onHorizontalDragUpdate: (details) {
                // Calculate which status to select based on drag position
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);

                final totalWidth = box.size.width;
                final position = localPosition.dx;

                // Determine which option to select (divide container into three sections)
                final sectionWidth = totalWidth / statusOptions.length;

                for (int i = 0; i < statusOptions.length; i++) {
                  if (position >= i * sectionWidth &&
                      position < (i + 1) * sectionWidth) {
                    if (selectedIndexNotifier.value != i) {
                      setDialogState(() {
                        selectedIndexNotifier.value = i;
                      });
                    }
                    break;
                  }
                }
              },
              onHorizontalDragEnd: (details) {
                // Close the dialog and update the status
                Navigator.of(context).pop();
                final newStatus = statusOptions[selectedIndexNotifier.value]
                    ['status'] as String;

                // Update the parent state
                setState(() {
                  _driverStatus = newStatus;
                });
              },
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Select Driver Status",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ValueListenableBuilder<int>(
                      valueListenable: selectedIndexNotifier,
                      builder: (context, selectedIndex, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children:
                                List.generate(statusOptions.length, (index) {
                              final color =
                                  statusOptions[index]['color'] as Color;
                              final isSelected = selectedIndex == index;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 18)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    index == 0
                                        ? "Active"
                                        : index == 1
                                            ? "Break"
                                            : "Unavail.",
                                    style: TextStyle(
                                      color:
                                          isSelected ? color : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Swipe to select",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).then((_) {
      // Cleanup the notifier when the dialog is closed
      selectedIndexNotifier.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      // Enable drawer edge gesture detection by default
      drawerEnableOpenDragGesture: true,
      // Prevent the view from resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      // Increase the area for swipe detection - fix the duplicate property
      drawerEdgeDragWidth: MediaQuery.of(context).size.width *
          0.5, // 30% of screen width for easier access
      drawer: NotificationDrawer(
        notifications: _notifications,
        onMarkAsRead: _markAsRead,
        onMarkAllAsRead: _markAllAsRead,
        hasUnreadNotifications: _hasUnreadNotifications,
      ),
      // Make drawer easy to open

      // Restore missing AppBar
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Hide default drawer icon
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
                      text: _firstName.isNotEmpty ? '$_firstName!' : 'Driver!',
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
                : Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () {
                        print(
                            'Avatar tapped, navigating to profile'); // Debug print
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DriverProfile(),
                          ),
                        );
                      },
                      borderRadius:
                          BorderRadius.circular(20), // Circular hit area
                      splashColor: const Color(0xFF6D6BF8).withOpacity(0.3),
                      highlightColor: Colors.white24,
                      child: Ink(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: _profilePictureUrl.isNotEmpty
                                  ? NetworkImage(_profilePictureUrl)
                                      as ImageProvider
                                  : const AssetImage(
                                      'assets/default_avatar.jpg'),
                              onBackgroundImageError: (_, __) {
                                setState(() {
                                  _profilePictureUrl =
                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_firstName)}&background=random';
                                });
                              },
                            ),
                            // Notification indicator on avatar
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
                    ),
                  ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Column(
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
                      title: _buildSearchBar(),
                    ),
                    SliverToBoxAdapter(
                      child: _filteredMessages.isEmpty
                          ? _buildNoVehiclesFoundWidget()
                          : ShaderMask(
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
                                  stops: [
                                    0.0,
                                    0.01,
                                    (!_isExpanded) ? 0.7 : 0.9,
                                    1.0
                                  ],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return VehicleDetails(
                                        entity: _filteredMessages[index]);
                                  },
                                  itemCount: _isExpanded
                                      ? _filteredMessages.length
                                      : _filteredMessages.length >
                                              _initialVehicleCount
                                          ? _initialVehicleCount
                                          : _filteredMessages.length,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Bottom Content (Fixed when not expanded)
              if (!_isExpanded)
                Container(
                  color: Colors.black,
                  padding: EdgeInsets.only(
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
                            top: 4.h,
                            bottom: 40.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildShowMoreButton()],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DriverHistoryPage()),
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
                      const SizedBox(height: 32),
                      _buildDriverStatusRow(),
                      const SizedBox(height: 32),
                      IconButton(
                        icon: Image.asset(
                          'assets/icons/qr_scanner.png',
                          width: 66.w,
                          height: 66.h,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ScanCodePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Show Less button when expanded
          if (_isExpanded &&
              _animationController != null &&
              _expandAnimation != null)
            AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return Positioned(
                  bottom: 20.h * (_expandAnimation?.value ?? 0),
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _expandAnimation!,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_buildShowMoreButton()],
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Replace the old notification circle with the new animated one
          if (_hasUnreadNotifications)
            DraggableNotificationCircle(
              notificationCount: _unreadNotificationCount,
              onDragComplete: () => _scaffoldKey.currentState?.openDrawer(),
              showIndicator: true,
            ),
        ],
      ),
    );
  }

  // New method to show UI when no vehicles found
  Widget _buildNoVehiclesFoundWidget() {
    return Container(
      height: 200.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .directions_car, // Using a valid icon that's guaranteed to exist
            size: 50,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20.h),
          Text(
            'No vehicles found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              _searchQuery.isNotEmpty ||
                      _selectedTypeFilter != 'All' ||
                      _selectedStatusFilter != 'All'
                  ? 'Try adjusting your filters or search query'
                  : 'There are no vehicles currently available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Driver Status',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(width: 12),
        _buildStatusToggleButton(),
      ],
    );
  }
}
