import 'package:flutter/material.dart';

class DashboardDriverPage extends StatelessWidget {
  const DashboardDriverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: const Center(child: Text('Dashboard Driver Page')),
    );
  }
}
