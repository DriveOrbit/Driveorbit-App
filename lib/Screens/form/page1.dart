import 'dart:io';
import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page2.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage>
    with SingleTickerProviderStateMixin {
  // List to store captured images (can be null if not taken yet)
  final List<File?> _vehiclePhotos = [null, null, null, null];
  final List<String> _photoLabels = ['Front', 'Back', 'Left', 'Right'];
  final ImagePicker _picker = ImagePicker();

  // Track loading state for each photo slot
  final List<bool> _isLoading = [false, false, false, false];

  // Animation controller for UI feedback
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for button and feedback animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Request camera permission on init
    _requestCameraPermission();

    // Initialize with an empty mileage value to ensure it's available
    _initializeMileage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Request camera permission proactively
  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
  }

  // Initialize mileage with 0 if not set already
  Future<void> _initializeMileage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('current_mileage')) {
      await prefs.setInt('current_mileage', 0);
    }
  }

  // Optimized photo capture with visual feedback
  Future<void> _takePhoto(int index) async {
    if (_isLoading[index]) return; // Prevent multiple simultaneous captures

    setState(() {
      _isLoading[index] = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Let image_picker handle permission logic
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Balance between quality and file size
        maxWidth: 1200, // Limit dimensions for performance
      );

      if (photo != null && mounted) {
        // Process the image in a non-blocking way
        setState(() {
          _vehiclePhotos[index] = File(photo.path);
          // Animate success feedback
          _animateSuccess();
        });
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error capturing image'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[index] = false;
        });
      }
    }
  }

  // Animation for success feedback
  void _animateSuccess() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  // View photo in full screen
  void _viewPhoto(int index) {
    if (_vehiclePhotos[index] == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: 'photo_$index',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(_vehiclePhotos[index]!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Check if all photos have been taken
  bool _allPhotosTaken() {
    return !_vehiclePhotos.contains(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Enhanced title with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Upload 4 side",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6D6BF8),
                        ),
                      ),
                      TextSpan(
                        text: " pictures\nof the vehicle",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF54C1D5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Progress indicator
              TweenAnimationBuilder(
                tween: Tween<double>(
                    begin: 0,
                    end: _vehiclePhotos.where((p) => p != null).length / 4),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${(_vehiclePhotos.where((p) => p != null).length)} of 4 photos",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${(value * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Grid to display the 4 photos with animations
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.9, // Slightly taller cells
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      transform: Matrix4.identity()
                        ..scale(_isLoading[index] ? 0.95 : 1.0),
                      child: GestureDetector(
                        onTap: () => _vehiclePhotos[index] != null
                            ? _viewPhoto(index)
                            : _takePhoto(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _vehiclePhotos[index] != null
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3)
                                    : Colors.black26,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: _vehiclePhotos[index] != null
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[800]!,
                              width: 2,
                            ),
                          ),
                          child: _isLoading[index]
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : _vehiclePhotos[index] != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Hero(
                                          tag: 'photo_$index',
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            child: Image.file(
                                              _vehiclePhotos[index]!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          left: 5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _photoLabels[index],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _vehiclePhotos[index] = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.refresh,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 30,
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _photoLabels[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to capture',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
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

              const SizedBox(height: 10),

              // Help text
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to capture, tap photo to preview',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Enhanced Next Button with animation
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()
                    ..scale(_allPhotosTaken() ? 1.0 : 0.95),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return ElevatedButton(
                        onPressed: _allPhotosTaken()
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MileageForm(),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: _allPhotosTaken() ? 8 : 0,
                          backgroundColor: _allPhotosTaken()
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Continue",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_allPhotosTaken()) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
