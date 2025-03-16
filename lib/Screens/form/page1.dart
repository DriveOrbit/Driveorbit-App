import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page2.dart'; // Import the second page (MileageForm)

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
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
              const SizedBox(height: 60),
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

              const SizedBox(height: 130),

              // Clickable "Take a Photo" Section
              GestureDetector(
                onTap: () {
                  // Implement camera functionality here
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/Camera.png',
                        width: 60,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 2,
                        height: 40,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tap",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "Please take clear photos",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 150),

              // Next Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the second page (MileageForm)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MileageForm()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
