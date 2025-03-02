import 'package:flutter/material.dart';
import 'package:driveorbit_app/Screens/form/page2.dart'; // Import the second page (MileageForm)

class PhotoUploadPage extends StatefulWidget {
  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  TextEditingController _inputController =
      TextEditingController(); // Controller for the input field

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("First Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction Text
            Text(
              "Enter your details",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),

            // Input Field
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Enter something here",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

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
                child: Text("Next", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
