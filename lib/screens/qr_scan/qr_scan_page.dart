import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/Screens/form/page1.dart';
import 'package:permission_handler/permission_handler.dart';

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

      // Navigation will happen after success animation completes
      Future.delayed(const Duration(seconds: 1), () {
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

                    if (barcodes.isNotEmpty && !_isScanning && mounted) {
                      for (final Barcode barcode in barcodes) {
                        debugPrint('Barcode found! ${barcode.rawValue}');
                      }

                      if (image != null) {
                        _handleSuccessfulScan();
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
