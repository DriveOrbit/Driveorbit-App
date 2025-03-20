import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/screens/vehicle_dasboard/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class PanicButtonPage extends StatefulWidget {
  const PanicButtonPage({Key? key}) : super(key: key);

  @override
  _PanicButtonPageState createState() => _PanicButtonPageState();
}

class _PanicButtonPageState extends State<PanicButtonPage> {
  bool panicComplete = false;
  bool fuelComplete = false;
  bool jobComplete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Panic Button
              SwipeButton.expand(
                thumb: Icon(Icons.double_arrow_rounded, color: Colors.white),
                child: Text(
                  panicComplete ? "Panic Done!" : "Panic",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                activeThumbColor: Colors.redAccent,
                activeTrackColor: Colors.red,
                onSwipe: () {
                  setState(() {
                    panicComplete = true;
                  });
                },
              ),

              // Fuel Button
              SwipeButton.expand(
                thumb: Icon(Icons.double_arrow_rounded, color: Colors.white),
                child: Text(
                  fuelComplete ? "Fuel Done!" : "Fuel",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                activeThumbColor: Colors.amberAccent,
                activeTrackColor: Colors.amber,
                onSwipe: () {
                  setState(() {
                    fuelComplete = true;
                  });
                },
              ),

              // Job Done Button
              SwipeButton.expand(
                thumb: Icon(Icons.double_arrow_rounded, color: Colors.white),
                child: Text(
                  jobComplete ? "Job Done!" : "Job",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                activeThumbColor: Colors.greenAccent,
                activeTrackColor: Colors.green,
                onSwipe: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DashboardDriverPage()),
                  );
                },
              ),

              // Close Button
              Container(
                width: 80,
                height: 80,
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/Nav-close.png',
                    width: 70.w, // Increased from 50.w
                    height: 70.w, // Increased from 50.w
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapPage()),
                    );
                    // Reset all buttons
                    // setState(() {
                    //   panicComplete = false;
                    //   fuelComplete = false;
                    //   jobComplete = false;
                    // });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
