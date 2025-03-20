import 'dart:io';
import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  // List to store captured images (can be null if not taken yet)
  final List<File?> _vehiclePhotos = [null, null, null, null];
  final List<String> _photoLabels = ['Front', 'Back', 'Left', 'Right'];
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  // Simplified approach to take photos
  Future<void> _takePhoto(int index) async {
    if (_isCapturing) return; // Prevent multiple simultaneous captures

    setState(() {
      _isCapturing = true;
    });

    try {
      // Let image_picker handle all permission logic
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() {
          _vehiclePhotos[index] = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error capturing image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              RichText(
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

              const SizedBox(height: 30),

              // Grid to display the 4 photos
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _takePhoto(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _vehiclePhotos[index] != null
                                ? Colors.green
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: _vehiclePhotos[index] != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _vehiclePhotos[index]!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _vehiclePhotos[index] = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
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
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _photoLabels[index],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Tap to capture',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),

              // Help text
              Center(
                child: Text(
                  'Tap on each box to take a photo with your camera',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Next Button
              Center(
                child: ElevatedButton(
                  onPressed: _allPhotosTaken()
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MileageForm()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: _allPhotosTaken()
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18)),
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
