import 'package:flutter/material.dart';

class VehicleInfoPage extends StatelessWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header will go here
                // Vehicle image will go here
                // Vehicle details will go here
                // Maintenance status will go here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
