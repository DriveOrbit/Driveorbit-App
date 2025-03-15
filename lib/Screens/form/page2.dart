import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MileageForm extends StatefulWidget {
  @override
  _MileageFormState createState() => _MileageFormState();
}

class _MileageFormState extends State<MileageForm> {
  TextEditingController mileageController = TextEditingController();
  bool isFullTank = true;
  bool isTyping = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clickable Mileage Input
              RichText(
                textAlign: TextAlign.left,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Enter your ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D6BF8),
                      ),
                    ),
                    TextSpan(
                      text: "current\n",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: "mileage",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Input Field
              GestureDetector(
                onTap: () {
                  setState(() {
                    isTyping = true;
                  });
                },
                child: TextField(
                  controller: mileageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text appears in black when typing
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: isTyping ? '' : "654 321 km",
                    hintStyle: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Clickable "Take a Photo" Section
              GestureDetector(
                onTap: () {
                  // Implement camera functionality here
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
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
                            "Take a photo of dashboard",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "Please take a clear photo",
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

              SizedBox(height: 40),

              // Fuel Status Question
              RichText(
                textAlign: TextAlign.left,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "What is your ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D6BF8),
                      ),
                    ),
                    TextSpan(
                      text: "current fuel\n",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                    TextSpan(
                      text: "status",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF54C1D5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Fuel Status Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  fuelStatusOption("Full tank", false),
                  fuelStatusOption("Need to tank full", true),
                ],
              ),

              SizedBox(height: 180),

              // Next button
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    // Implement navigation or next action
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: Icon(Icons.arrow_forward,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget fuelStatusOption(String text, bool value) {
    bool isSelected = isFullTank == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          isFullTank = value; // Update state on tap
        });
      },
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            color: isSelected ? Colors.green : Colors.white,
          ),
          SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.green : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
