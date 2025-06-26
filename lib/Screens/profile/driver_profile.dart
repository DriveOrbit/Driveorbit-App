import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:driveorbit_app/Screens/auth/login_page.dart'; // Add this import

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        setState(() {
          _error = 'Driver profile not found. Please contact administrator.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userData = userDoc.data()!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Simply pop back to the previous screen instead of explicitly navigating to MapPage
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Driver Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadUserData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ResponsiveLayout(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfileHeader(
                            firstName: _userData['firstName'] ?? '',
                            lastName: _userData['lastName'] ?? '',
                            profilePictureUrl: _userData['profilePicture'],
                          ),
                          const SizedBox(height: 24),
                          AnimatedInfoCard(
                            title: 'Personal Information',
                            icon: Icons.person,
                            child: Column(
                              children: [
                                InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'First Name',
                                  value: _userData['firstName'] ?? 'Not set',
                                ),
                                InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Last Name',
                                  value: _userData['lastName'] ?? 'Not set',
                                ),
                                InfoRow(
                                  icon: Icons.badge,
                                  label: 'Driver ID',
                                  value:
                                      _userData['driverId'] ?? 'Not assigned',
                                ),
                                InfoRow(
                                  icon: Icons.credit_card,
                                  label: 'NIC Number',
                                  value: _userData['nicNumber'] ??
                                      'Not registered',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedInfoCard(
                            title: 'Contact Information',
                            icon: Icons.contact_phone,
                            child: Column(
                              children: [
                                InfoRow(
                                  icon: Icons.phone,
                                  label: 'Phone',
                                  value: _userData['phone'] ?? 'Not set',
                                ),
                                InfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: _userData['email'] ??
                                      FirebaseAuth
                                          .instance.currentUser?.email ??
                                      'Not set',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedInfoCard(
                            title: 'Status Information',
                            icon: Icons.info_outline,
                            child: Column(
                              children: [
                                InfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Joined',
                                  value: _userData['joinDate'] != null
                                      ? _formatTimestamp(_userData['joinDate'])
                                      : 'Not available',
                                ),
                                InfoRow(
                                  icon: Icons.check_circle,
                                  label: 'Status',
                                  value: _userData['status'] ?? 'Unknown',
                                  valueColor:
                                      _getStatusColor(_userData['status']),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          const LogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMMM d, yyyy').format(timestamp.toDate());
    } else {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SizedBox(
            width: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
            child: child,
          ),
        );
      },
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;

  const ProfileHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey,
            backgroundImage: _getProfileImage(),
            child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.white54)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$firstName $lastName',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      return NetworkImage(profilePictureUrl!);
    }
    return null;
  }
}

class AnimatedInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const AnimatedInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          if (trailing != null) ...[
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 8),
            trailing!,
          ] else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await FirebaseAuth.instance.signOut();

                        // Show a brief success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        // Navigate to login page
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      } catch (e) {
                        // Handle the PigeonUserDetails error specifically
                        final String errorText = e.toString();
                        if (errorText.contains("'List<Object?>") &&
                            errorText.contains("'PigeonUserDetails?'")) {
                          debugPrint(
                              'PigeonUserDetails error caught, proceeding with logout flow');

                          // Despite the error, Firebase Auth usually completes the signout
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged out successfully'),
                              duration: Duration(seconds: 1),
                            ),
                          );

                          // Navigate to login page
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        } else {
                          // Handle other errors
                          debugPrint('Error during logout: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error logging out: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text(
                      'LOGOUT',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
        label: const Text(
          'LOGOUT',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
