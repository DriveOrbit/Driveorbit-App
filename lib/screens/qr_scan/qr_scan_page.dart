import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/dashboard/dashboard_driver_page.dart';

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
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(barcodes.first.rawValue ?? ""),
                      content: Image(
                        image: MemoryImage(image),
                      ),
                    );
                  },
                );
              }
            },
          ),

          // Close button positioned at the bottom center
          Positioned(
            bottom: 40, // Adjust the distance from the bottom
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 36,
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
