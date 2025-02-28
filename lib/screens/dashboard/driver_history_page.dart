import 'dart:convert';

import 'package:driveorbit_app/models/driver_history_entity.dart';
import 'package:driveorbit_app/widgets/driving_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  List<DrivingHistoryEntity> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final response =
        await rootBundle.loadString('assets/mock_drivinghistory.json');
    final List<dynamic> decodedList = jsonDecode(response);
    final List<DrivingHistoryEntity> history =
        decodedList.map((item) => DrivingHistoryEntity.fromJson(item)).toList();

    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return DrivingHistoryItem(history: _history[index]);
        },
      ),
    );
  }
}
