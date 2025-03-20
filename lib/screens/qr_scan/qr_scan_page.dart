import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';
import 'package:driveorbit_app/Screens/form/page1.dart'; // Import page1

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // QR Code Scanner
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              returnImage: true,
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              final Uint8List? image = capture.image;
              for (final Barcode barcode in barcodes) {
                print('Barcode found! ${barcode.rawValue}');
              }
              if (image != null) {
                // Navigate to form page1 after QR scan detection
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoUploadPage(),
                  ),
                );
              }
            },
          ),

          // Close button positioned at the bottom center
          Positioned(
            bottom: 55,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                iconSize: 66, // Maintain the same icon button size
                padding: EdgeInsets.zero, // Maintain zero padding
                icon: Image.asset(
                  'assets/icons/Nav-close.png',
                  width: 55,
                  height: 60, // Maintain the same dimensions
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardDriverPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
