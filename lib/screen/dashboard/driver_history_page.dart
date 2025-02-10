import 'package:flutter/material.dart';

class DriverHistoryPage extends StatelessWidget {
  const DriverHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driving History')),
      body: const Center(child: Text('Driving History Page')),
    );
  }
}
