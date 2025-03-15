import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page2.dart'; // Import the second page (MileageForm)

class PhotoUploadPage extends StatefulWidget {
  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  TextEditingController _inputController = TextEditingController(); // Controller for the input field

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruction Text
              RichText(
                textAlign: TextAlign.left,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Upload 4 side",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D6BF8),
                      ),
                    ),
                    TextSpan(
                      text: " pictures\n",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: "of the vehicle",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.black),
                      SizedBox(width: 10),
                      Column(
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

              const Spacer(), // Pushes the Next button to the bottom

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
                  child: const Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
