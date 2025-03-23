import 'dart:typed_data';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/Screens/form/page1.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _scanSuccess = false;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  String _errorMessage = "Initializing camera...";
  bool _isProcessingQR = false;

  // Add a cache of recently scanned QR codes to prevent multiple processing
  final Map<String, DateTime> _recentlyScannedCodes = {};
  // Add a debounce timer
  Timer? _scanDebounceTimer;
  // Track the last scanned code
  String? _lastScannedCode;

  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Check camera permission before initializing
    _checkPermissionAndInitCamera();
  }

  Future<void> _checkPermissionAndInitCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _initializeCamera();
      } else {
        setState(() {
          _hasCameraError = true;
          _errorMessage =
              "Camera permission denied. Please enable it in settings.";
        });
      }
    } catch (e) {
      setState(() {
        _hasCameraError = true;
        _errorMessage = "Error requesting camera permission: $e";
      });
      debugPrint("Permission error: $e");
    }
  }

  void _initializeCamera() {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: true,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Wait a short time and assume camera started if no errors
      // This is a workaround since there's no direct onStarted callback
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasCameraError) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasCameraError = true;
        _errorMessage = "Failed to initialize camera: $e";
      });
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController?.dispose();
    _scanDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _processQRCode(String? qrValue) async {
    if (qrValue == null || _isProcessingQR) return;

    // Prevent duplicate scans of the same QR code
    if (_lastScannedCode == qrValue) {
      // Check if we've scanned this code recently (within 5 seconds)
      final lastScanTime = _recentlyScannedCodes[qrValue];
      if (lastScanTime != null) {
        final timeSinceLastScan = DateTime.now().difference(lastScanTime);
        if (timeSinceLastScan.inSeconds < 5) {
          debugPrint(
              'Ignoring duplicate QR scan (${timeSinceLastScan.inMilliseconds}ms since last scan)');
          return;
        }
      }
    }

    // Cancel any existing debounce timer
    _scanDebounceTimer?.cancel();

    // Update the last scanned code and timestamp
    _lastScannedCode = qrValue;
    _recentlyScannedCodes[qrValue] = DateTime.now();

    // Set debounce timer to prevent rapid rescans
    _scanDebounceTimer = Timer(const Duration(seconds: 5), () {
      // After 5 seconds, allow rescanning this code
      if (_lastScannedCode == qrValue) {
        _lastScannedCode = null;
      }
    });

    setState(() {
      _isProcessingQR = true;
    });

    try {
      debugPrint('==== QR CODE SCAN DEBUG ====');
      debugPrint('Processing QR code: $qrValue');

      // Normalize the QR value (handle URL formats if needed)
      String normalizedQrValue = qrValue.trim();

      // Show a loading indicator during processing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        },
      );

      // Try to parse the custom format first
      final Map<String, String> parsedData =
          _parseVehicleQRCode(normalizedQrValue);
      debugPrint('Parsed QR data: $parsedData');

      // If we have a vehicle ID from parsing, use that directly
      String? vehicleId = parsedData['vehicle'];
      QuerySnapshot? vehicleSnapshot;

      // Try to fetch the vehicle with retry mechanism
      vehicleSnapshot = await _tryFirestoreOperation(() async {
        QuerySnapshot snapshot;

        if (vehicleId != null) {
          debugPrint('Using parsed vehicle ID: $vehicleId');
          snapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .where('vehicleId',
                  isEqualTo: int.tryParse(vehicleId) ?? vehicleId)
              .limit(1)
              .get();

          if (snapshot.docs.isEmpty) {
            // Try as string if numeric didn't work
            snapshot = await FirebaseFirestore.instance
                .collection('vehicles')
                .where('vehicleId', isEqualTo: vehicleId)
                .limit(1)
                .get();
          }
        } else {
          // First try exact match with qrCodeURL
          debugPrint('Approach 1: Trying exact match...');
          snapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .where('qrCodeURL', isEqualTo: normalizedQrValue)
              .limit(1)
              .get();
        }

        return snapshot;
      });

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Handle case when vehicleSnapshot is still null after retries
      if (vehicleSnapshot == null) {
        _showConnectivityErrorDialog(
            'Failed to connect to the database after multiple attempts.');
        return;
      }

      if ((vehicleId != null && vehicleSnapshot.docs.isEmpty) ||
          (vehicleId == null && vehicleSnapshot.docs.isEmpty)) {
        // QR code parsed but vehicle not found - try one more direct approach with the model and number
        if (parsedData.containsKey('model') &&
            parsedData.containsKey('number')) {
          debugPrint('Trying to match by model and number...');
          final model = parsedData['model'];
          final number = parsedData['number'];

          if (model != null && number != null) {
            vehicleSnapshot = await _tryFirestoreOperation(() async {
              return await FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('vehicleModel', isEqualTo: model)
                  .where('vehicleNumber', isEqualTo: number)
                  .limit(1)
                  .get();
            });

            // Check if we still have a connection error
            if (vehicleSnapshot == null) {
              _showConnectivityErrorDialog(
                  'Failed to connect to the database after multiple attempts.');
              return;
            }
          }
        }
      }

      if (vehicleSnapshot.docs.isEmpty) {
        // QR code is not registered - provide more detailed error
        debugPrint('No matching vehicle found for QR code');

        // Show the detailed error with parsed data for better debugging
        _showDetailedErrorDialog(normalizedQrValue, parsedData);
        return;
      }

      // Get vehicle data
      final vehicleData =
          vehicleSnapshot.docs.first.data() as Map<String, dynamic>;
      final docId = vehicleSnapshot.docs.first.id;
      final vehicle = VehicleDetailsEntity.fromMap(vehicleData);

      debugPrint('Success! Found vehicle: ${vehicle.vehicleModel} (${docId})');

      // Check if current user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorDialog(
            'Authentication Error', 'You need to be logged in to start a job.');
        setState(() {
          _isProcessingQR = false;
        });
        return;
      }

      // Get user data for the job record with retry
      final userSnapshot = await _tryFirestoreOperation(() async {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
      });

      // Handle connection error
      if (userSnapshot == null) {
        _showConnectivityErrorDialog(
            'Failed to fetch user data. Please check your connection.');
        return;
      }

      final userData = userSnapshot.data() ?? {};
      final userName = userData['name'] ?? 'Unknown Driver';

      // Show confirmation dialog
      if (mounted) {
        _showVehicleConfirmationDialog(
            vehicle, docId, userName, currentUser.uid);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('Error processing QR code: $e');

      // Handle Firestore connectivity issues
      if (e.toString().contains('unavailable') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        _showConnectivityErrorDialog(
            'Database connection error: ${e.toString()}');
      } else {
        _showErrorDialog('Error', 'Failed to process QR code: $e');
      }

      setState(() {
        _isProcessingQR = false;
      });
    }
  }

  // Helper method to retry Firestore operations with exponential backoff
  Future<T?> _tryFirestoreOperation<T>(Future<T> Function() operation) async {
    const maxRetries = 3;
    int retryCount = 0;
    int retryDelayMs = 500; // Start with 500ms delay

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        debugPrint('Firestore operation failed (attempt $retryCount): $e');

        // Check if it's a permission error - no need to retry
        if (e.toString().contains('permission-denied') ||
            e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('insufficient permissions')) {
          rethrow; // Don't retry for permission errors
        }

        // Check if we've reached max retries
        if (retryCount >= maxRetries) {
          debugPrint('Max retries reached, giving up.');
          return null;
        }

        // If the error is not connectivity-related, rethrow it
        if (!e.toString().contains('unavailable') &&
            !e.toString().contains('network') &&
            !e.toString().contains('connection')) {
          rethrow;
        }

        // Wait with exponential backoff before retrying
        await Future.delayed(Duration(milliseconds: retryDelayMs));
        retryDelayMs *= 2; // Exponential backoff
      }
    }

    return null;
  }

  // Show connectivity error dialog with retry option
  void _showConnectivityErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Connection Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Please check your internet connection and try again.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset the scanner to scan again
              setState(() {
                _isProcessingQR = false;
                _isScanning = false;
                _scanSuccess = false;
              });
              _scannerController?.start();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Try again with the same QR code
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                // Force a debug match to test if connection is working
                _debugForceVehicleMatch();
              } else {
                setState(() {
                  _isProcessingQR = false;
                  _isScanning = false;
                  _scanSuccess = false;
                });
                _scannerController?.start();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Parse the custom vehicle QR code format
  Map<String, String> _parseVehicleQRCode(String qrContent) {
    Map<String, String> result = {};

    try {
      // Handle both data URL and direct content formats
      String content = qrContent;

      // If content is a data URL, try to extract the last part
      if (qrContent.contains('data:') || qrContent.contains('://')) {
        final Uri uri = Uri.parse(qrContent);
        if (uri.pathSegments.isNotEmpty) {
          content = uri.pathSegments.last;
        }
      }

      // Try to find the vehicle:X|number:Y|model:Z format
      if (content.contains('vehicle:') || content.contains('|')) {
        List<String> parts = content.split('|');

        for (String part in parts) {
          List<String> keyValue = part.split(':');
          if (keyValue.length == 2) {
            String key = keyValue[0].trim();
            String value = keyValue[1].trim();
            result[key] = value;
          }
        }

        debugPrint('Successfully parsed vehicle data format: $result');
      }
    } catch (e) {
      debugPrint('Error parsing QR code: $e');
    }

    return result;
  }

  // Update the detailed error dialog to show parsed data
  void _showDetailedErrorDialog(String qrValue,
      [Map<String, String>? parsedData]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Not Recognized'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The scanned QR code was not found in our system.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Debugging information:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Content:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        qrValue,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Length: ${qrValue.length} characters',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    // Add parsed data section if available
                    if (parsedData != null && parsedData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Parsed Vehicle Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: parsedData.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: RichText(
                                text: TextSpan(
                                  text: '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontFamily: 'monospace',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: entry.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Support Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If this is a correct QR code for a vehicle, please contact support with a screenshot of this page.',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The QR code might need to be registered or updated in the system.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset the scanner to scan again
              setState(() {
                _isScanning = false;
                _scanSuccess = false;
                _isProcessingQR = false;
              });
              _scannerController?.start();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              // For debugging - force a success case to test the rest of the flow
              Navigator.pop(context);
              _debugForceVehicleMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Debug Override'),
          ),
        ],
      ),
    );
  }

  Future<void> _createJobRecord(String vehicleId, String vehicleName,
      String driverUid, String driverName) async {
    try {
      // Generate a unique job ID
      final jobId = const Uuid().v4();

      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        },
      );

      // Get mileage and fuel status from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentMileage = prefs.getInt('current_mileage') ?? 0;
      final isFuelTankFull = prefs.getBool('fuel_tank_full') ?? true;

      // Store the jobId in SharedPreferences so we can update it later
      await prefs.setString('current_job_id', jobId);

      // Store the vehicle ID in SharedPreferences for job assignments
      await prefs.setString('current_vehicle_id', vehicleId);

      // Try to create job record with retry mechanism
      bool success = false;
      Exception? lastError;
      bool isPermissionError = false;

      for (int i = 0; i < 3; i++) {
        try {
          // Create the job record with additional mileage and fuel status data
          await FirebaseFirestore.instance.collection('jobs').doc(jobId).set({
            'jobId': jobId,
            'vehicleId': vehicleId,
            'vehicleName': vehicleName,
            'driverUid': driverUid,
            'driverName': driverName,
            'startTime': FieldValue.serverTimestamp(),
            'startDate': DateTime.now().toString().split(' ')[0],
            'endTime': null,
            'status': 'started',
            'createdAt': FieldValue.serverTimestamp(),
            // Initial mileage and fuel values
            'startMileage': currentMileage,
            'endMileage': null, // Will be filled when job is completed
            'fuelStatus': isFuelTankFull ? 'Full tank' : 'Refuel needed',
            'isFuelTankFull': isFuelTankFull, // Boolean value for filtering
            'dashboardPhotoUrl': null, // Will be filled in the next step
          });

          success = true;
          break;
        } catch (e) {
          lastError = e as Exception;
          debugPrint('Error creating job record (attempt ${i + 1}): $e');

          // Check if it's a permission error - no need to retry
          if (e.toString().contains('permission-denied') ||
              e.toString().contains('PERMISSION_DENIED') ||
              e.toString().contains('insufficient permissions')) {
            isPermissionError = true;
            break; // Don't retry for permission errors
          }

          // If the error is not connectivity-related, don't retry
          if (!e.toString().contains('unavailable') &&
              !e.toString().contains('network') &&
              !e.toString().contains('connection')) {
            break;
          }

          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }

      if (success) {
        // Navigate to the next page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  const PhotoUploadPage(),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      } else {
        // Show specific error dialog for permission errors
        if (isPermissionError) {
          _showPermissionErrorDialog();
        } else {
          // Show general error with retry option
          _showJobCreationErrorDialog(
            vehicleId,
            vehicleName,
            driverUid,
            driverName,
            lastError.toString(),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('Error creating job record: $e');

      // Check for permission error
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('insufficient permissions')) {
        _showPermissionErrorDialog();
      } else {
        _showErrorDialog('Error', 'Failed to create job record: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingQR = false;
        });
      }
    }
  }

  // Show special dialog for permission errors
  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Permission Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account does not have permission to create job records.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This is likely due to one of the following reasons:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildErrorBulletPoint(
                        'Your account may not have the required role or permissions.'),
                    _buildErrorBulletPoint(
                        'Firebase security rules are restricting write access to the jobs collection.'),
                    _buildErrorBulletPoint(
                        'The system administrator needs to update your access level.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'For Administrators',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update Firestore security rules to allow write access to the jobs collection for appropriate user roles.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const SelectableText(
                        'match /databases/{database}/documents {\n'
                        '  match /jobs/{jobId} {\n'
                        '    allow read: if request.auth != null;\n'
                        '    allow write: if request.auth != null && (request.auth.uid == request.resource.data.driverUid || hasRole(\'admin\'));\n'
                        '  }\n'
                        '}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Return to the dashboard
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const DashboardDriverPage(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  // Helper for bullet points in error dialog
  Widget _buildErrorBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showJobCreationErrorDialog(String vehicleId, String vehicleName,
      String driverUid, String driverName, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Job Creation Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not save job details to the database due to a connection issue.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: ${errorMessage.replaceAll(RegExp(r'\[.*?\]'), '')}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your internet connection and try again.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset everything
              setState(() {
                _isProcessingQR = false;
                _isScanning = false;
                _scanSuccess = false;
              });
              _scannerController?.start();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Try again
              _createJobRecord(vehicleId, vehicleName, driverUid, driverName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset the scanner to scan again
              setState(() {
                _isScanning = false;
                _scanSuccess = false;
              });
              _scannerController?.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVehicleConfirmationDialog(VehicleDetailsEntity vehicle,
      String vehicleId, String driverName, String driverUid) {
    bool isDragComplete = false;
    double dragProgress = 0.0;
    final double dragThreshold = 100; // Distance needed to drag

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate the width of the dialog more safely
          final double dialogWidth = MediaQuery.of(context).size.width *
              0.7; // Fixed width for calculations
          final double endDragPosition =
              dialogWidth - 60; // End position considering button width

          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Vehicle Confirmation',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Use a SingleChildScrollView to prevent overflow
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.6, // Limit max height
                maxWidth:
                    MediaQuery.of(context).size.width * 0.8, // Limit max width
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row - vehicle model question
                    Text(
                      'Is this ${vehicle.vehicleModel}?',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Vehicle details container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plate number row
                          Row(
                            children: [
                              Icon(Icons.credit_card,
                                  size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Plate Number: ${vehicle.plateNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Vehicle type row
                          Row(
                            children: [
                              Icon(Icons.category,
                                  size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Type: ${vehicle.vehicleType}',
                                  style: TextStyle(color: Colors.grey.shade800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animated instruction - use fixed size constraints
                    SizedBox(
                      width: double.infinity,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, sin(value * 2 * pi) * 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swipe_right_alt,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Slide to start job',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slider container with fixed width
                    SizedBox(
                      height: 60,
                      width: dialogWidth,
                      child: Stack(
                        children: [
                          // Background container
                          Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                  Colors.grey.shade200,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          // Track progress indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: isDragComplete
                                ? dialogWidth
                                : dragProgress * dialogWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: isDragComplete
                                    ? [
                                        Colors.green.shade300,
                                        Colors.green.shade500,
                                        Colors.green.shade400,
                                      ]
                                    : [
                                        Colors.blue.shade200,
                                        Colors.blue.shade300,
                                        Colors.blue.shade200,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),

                          // Draggable button with smooth animation
                          AnimatedPositioned(
                            duration: isDragComplete
                                ? const Duration(milliseconds: 300)
                                : const Duration(milliseconds: 50),
                            curve: isDragComplete
                                ? Curves.easeOutBack
                                : Curves.linear,
                            left: isDragComplete
                                ? endDragPosition
                                : dragProgress * endDragPosition,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onHorizontalDragUpdate: isDragComplete
                                  ? null
                                  : (details) {
                                      // Update drag progress with fixed width calculation
                                      final double dragX = details
                                          .localPosition.dx
                                          .clamp(0.0, dialogWidth);
                                      final double newProgress =
                                          (dragX / dialogWidth).clamp(0.0, 1.0);

                                      setState(() {
                                        dragProgress = newProgress;
                                      });

                                      // Check if we've reached the completion threshold
                                      if (newProgress >= 0.7) {
                                        // 70% of the way
                                        setState(() {
                                          isDragComplete = true;
                                        });

                                        // Trigger feedback
                                        HapticFeedback.mediumImpact();

                                        // Success animation and completion
                                        Future.delayed(
                                            const Duration(milliseconds: 600),
                                            () {
                                          Navigator.pop(context);
                                          _handleSuccessfulScan();
                                          _createJobRecord(
                                              vehicleId,
                                              vehicle.vehicleModel,
                                              driverUid,
                                              driverName);
                                        });
                                      }
                                    },
                              onHorizontalDragEnd: isDragComplete
                                  ? null
                                  : (details) {
                                      // If not completed, snap back to start
                                      if (!isDragComplete) {
                                        setState(() {
                                          dragProgress = 0.0;
                                        });
                                      }
                                    },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isDragComplete
                                        ? [
                                            Colors.green.shade400,
                                            Colors.green.shade600
                                          ]
                                        : [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDragComplete
                                              ? Colors.green
                                              : Colors.blue)
                                          .withOpacity(0.3),
                                      blurRadius: isDragComplete ? 12 : 8,
                                      spreadRadius: isDragComplete ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: isDragComplete
                                      ? const Icon(
                                          Icons.check,
                                          key: ValueKey('check'),
                                          color: Colors.white,
                                          size: 30,
                                        )
                                      : Icon(
                                          dragProgress > 0.4
                                              ? Icons.chevron_right
                                              : Icons.arrow_forward,
                                          key: ValueKey(dragProgress > 0.4
                                              ? 'chevron'
                                              : 'arrow'),
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                ),
                              ),
                            ),
                          ),

                          // Show "completed" text when finished
                          if (isDragComplete)
                            Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: const Text(
                                      'Job Started!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Show confirmation message when close to completion
                    if (dragProgress > 0.4 && !isDragComplete)
                      AnimatedOpacity(
                        opacity: ((dragProgress - 0.4) * 2.5).clamp(0.0, 1.0),
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Almost there! Keep sliding...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (!isDragComplete)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Reset the scanner to scan again
                    setState(() {
                      _isProcessingQR = false;
                      _isScanning = false;
                      _scanSuccess = false;
                    });
                    _scannerController?.start();
                  },
                  child: const Text('Cancel'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleSuccessfulScan() {
    if (!_isScanning) {
      setState(() {
        _isScanning = true;
        _scanSuccess = true;
      });

      // Stop the scanning animation
      _animationController.stop();

      // Play the success animation
      _animationController.duration = const Duration(milliseconds: 300);
      _animationController.forward(from: 0.0);

      // Release camera resources early
      _scannerController?.stop();
    }
  }

  // For debugging only - force a match to test the flow
  Future<void> _debugForceVehicleMatch() async {
    try {
      // Get the first vehicle from the database
      final vehicles = await FirebaseFirestore.instance
          .collection('vehicles')
          .limit(1)
          .get();

      if (vehicles.docs.isEmpty) {
        _showErrorDialog('Debug Error', 'No vehicles found in database.');
        setState(() {
          _isProcessingQR = false;
        });
        return;
      }

      final vehicleData = vehicles.docs.first.data();
      final vehicleId = vehicles.docs.first.id;
      final vehicle = VehicleDetailsEntity.fromMap(vehicleData);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorDialog(
            'Authentication Error', 'You need to be logged in to start a job.');
        setState(() {
          _isProcessingQR = false;
        });
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userSnapshot.data() ?? {};
      final userName = userData['name'] ?? 'Unknown Driver';

      _showVehicleConfirmationDialog(
          vehicle, vehicleId, userName, currentUser.uid);
    } catch (e) {
      _showErrorDialog('Debug Error', 'Error: $e');
      setState(() {
        _isProcessingQR = false;
      });
    }
  }

  Widget _buildScannerOverlay(BuildContext context, double scanAreaSize) {
    return ClipPath(
      clipper: ScannerOverlayClipper(scanAreaSize: scanAreaSize),
      child: Container(
        color: Colors.black.withOpacity(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scanAreaSize = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // QR Code Scanner with error handling
          if (_hasCameraError)
            // Show error message if camera failed to initialize
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Try to reinitialize camera
                        setState(() {
                          _hasCameraError = false;
                          _errorMessage = "Initializing camera...";
                        });
                        _checkPermissionAndInitCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          else if (_scannerController != null)
            Stack(
              children: [
                // The scanner view
                MobileScanner(
                  controller: _scannerController!,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    final Uint8List? image = capture.image;

                    // Set camera as initialized once we get a barcode capture event
                    // This ensures the camera is working
                    if (!_isCameraInitialized && mounted) {
                      setState(() {
                        _isCameraInitialized = true;
                      });
                    }

                    if (barcodes.isNotEmpty &&
                        !_isScanning &&
                        !_isProcessingQR &&
                        mounted) {
                      for (final Barcode barcode in barcodes) {
                        final String? rawValue = barcode.rawValue;
                        if (rawValue != null) {
                          debugPrint('Barcode found! $rawValue');
                          if (image != null) {
                            // Process the QR code with debouncing
                            _processQRCode(rawValue);
                            break; // Process only the first barcode
                          }
                        }
                      }
                    }
                  },
                  errorBuilder: (context, error, child) {
                    // Handle camera errors that occur during scanning
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_hasCameraError) {
                        setState(() {
                          _hasCameraError = true;
                          _errorMessage = "Camera error: ${error.toString()}";
                        });
                        debugPrint("Camera error in errorBuilder: $error");
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),

                // Show initialization overlay while camera is starting
                if (!_isCameraInitialized)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Starting camera...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Scanner overlay with cutout
          if (!_hasCameraError) _buildScannerOverlay(context, scanAreaSize),

          // Scanning frame and animation
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scanSuccess ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _scanSuccess ? Colors.green : Colors.white,
                          width: 2.0),
                      borderRadius: BorderRadius.circular(12),
                      color: _scanSuccess
                          ? Colors.green.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    child: Stack(
                      children: [
                        // Scanning animation line
                        if (!_scanSuccess)
                          AnimatedBuilder(
                            animation: _scanLineAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 5 +
                                    (_scanLineAnimation.value *
                                        (scanAreaSize - 10)),
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0),
                                        Colors.blue.withOpacity(0.8),
                                        Colors.blue.withOpacity(0),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Success icon animation
                        if (_scanSuccess)
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Corner decorations
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    left: -5,
                    top: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _scanSuccess ? Colors.green : Colors.blue,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _scanSuccess ? Colors.green : Colors.blue,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -5,
                    bottom: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _scanSuccess ? Colors.green : Colors.blue,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _scanSuccess ? Colors.green : Colors.blue,
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructional text
          if (!_scanSuccess)
            Positioned(
              bottom: screenSize.height * 0.3,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Position the QR code within the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Success message that appears when scan is successful
          if (_scanSuccess)
            Positioned(
              top: screenSize.height * 0.15,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: LayoutBuilder(builder: (context, constraints) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "QR Code Scanned Successfully!",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Close button
          Positioned(
            bottom: screenSize.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
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
                            const DashboardDriverPage(),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
    );
  }
}

// Custom clipper for scanner overlay
class ScannerOverlayClipper extends CustomClipper<Path> {
  final double scanAreaSize;

  ScannerOverlayClipper({required this.scanAreaSize});

  @override
  Path getClip(Size size) {
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(ScannerOverlayClipper oldClipper) =>
      oldClipper.scanAreaSize != scanAreaSize;
}
