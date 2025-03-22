import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/Screens/form/page1.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';

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
    super.dispose();
  }

  Future<void> _processQRCode(String? qrValue) async {
    if (qrValue == null || _isProcessingQR) return;

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
      final Map<String, String> parsedData = _parseVehicleQRCode(normalizedQrValue);
      debugPrint('Parsed QR data: $parsedData');
      
      // If we have a vehicle ID from parsing, use that directly
      String? vehicleId = parsedData['vehicle'];
      QuerySnapshot vehicleSnapshot;
      
      if (vehicleId != null) {
        debugPrint('Using parsed vehicle ID: $vehicleId');
        vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('vehicleId', isEqualTo: int.tryParse(vehicleId) ?? vehicleId)
            .limit(1)
            .get();
            
        if (vehicleSnapshot.docs.isEmpty) {
          // Try as string if numeric didn't work
          vehicleSnapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .where('vehicleId', isEqualTo: vehicleId)
              .limit(1)
              .get();
        }
      } else {
        // Try the approaches from before if parsing failed
        // First try exact match with qrCodeURL
        debugPrint('Approach 1: Trying exact match...');
        vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('qrCodeURL', isEqualTo: normalizedQrValue)
            .limit(1)
            .get();
        
        // Try other approaches if needed (existing code)
        // ...
      }
      
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if ((vehicleId != null && vehicleSnapshot.docs.isEmpty) || 
          (vehicleId == null && vehicleSnapshot.docs.isEmpty)) {
        // QR code parsed but vehicle not found - try one more direct approach with the model and number
        if (parsedData.containsKey('model') && parsedData.containsKey('number')) {
          debugPrint('Trying to match by model and number...');
          final model = parsedData['model'];
          final number = parsedData['number'];
          
          if (model != null && number != null) {
            vehicleSnapshot = await FirebaseFirestore.instance
                .collection('vehicles')
                .where('vehicleModel', isEqualTo: model)
                .where('vehicleNumber', isEqualTo: number)
                .limit(1)
                .get();
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
      final vehicleData = vehicleSnapshot.docs.first.data() as Map<String, dynamic>;
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

      // Get user data for the job record
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

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
      _showErrorDialog('Error', 'Failed to process QR code: $e');
      setState(() {
        _isProcessingQR = false;
      });
    }
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
  void _showDetailedErrorDialog(String qrValue, [Map<String, String>? parsedData]) {
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

      // Create the job record
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).set({
        'jobId': jobId,
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'driverUid': driverUid,
        'driverName': driverName,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'status': 'started',
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    } catch (e) {
      debugPrint('Error creating job record: $e');
      _showErrorDialog('Error', 'Failed to create job record: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingQR = false;
        });
      }
    }
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
    final double dragThreshold = 100; // Distance needed to drag
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Vehicle Confirmation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Is this ${vehicle.vehicleModel}?'),
                const SizedBox(height: 8),
                Text('Plate Number: ${vehicle.plateNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Type: ${vehicle.vehicleType}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                const Text(
                  'Slide button to start job →',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        left: isDragComplete 
                            ? MediaQuery.of(context).size.width - 200  // End position
                            : 0,                                      // Start position
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onHorizontalDragUpdate: isDragComplete
                              ? null 
                              : (details) {
                                  // Calculate the position of the draggable button
                                  final RenderBox box = context.findRenderObject() as RenderBox;
                                  final Offset localOffset = box.globalToLocal(details.globalPosition);
                                  
                                  if (localOffset.dx >= dragThreshold) {
                                    setState(() {
                                      isDragComplete = true;
                                    });
                                    
                                    // Close dialog and proceed
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      Navigator.pop(context);
                                      _handleSuccessfulScan();
                                      _createJobRecord(
                                          vehicleId, vehicle.vehicleModel, driverUid, driverName);
                                    });
                                  }
                                },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDragComplete ? Colors.green : Colors.green.shade600,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isDragComplete
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Visual progress indicator
                      if (isDragComplete)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
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
      
      _showVehicleConfirmationDialog(vehicle, vehicleId, userName, currentUser.uid);
      
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
                        debugPrint('Barcode found! ${barcode.rawValue}');
                        if (image != null) {
                          // Process the QR code with Firestore check
                          _processQRCode(barcode.rawValue);
                          break; // Process only the first barcode
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
                            vertical: 12, horizontal: 24),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "QR Code Scanned Successfully!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
