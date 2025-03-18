import 'package:flutter/material.dart';
import 'package:driveorbit_app/widgets/job_card.dart';
import 'dart:convert';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:flutter/services.dart';

class JobAssignedPage extends StatefulWidget {
  const JobAssignedPage({super.key});

  @override
  State<JobAssignedPage> createState() => _JobAssignedPageState();
}

class _JobAssignedPageState extends State<JobAssignedPage> {
  List<JobDetailsEntity> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final response = await rootBundle.loadString('assets/mock_jobdetails.json');
    final List<dynamic> decodedList = jsonDecode(response);
    final List<JobDetailsEntity> history =
        decodedList.map((item) => JobDetailsEntity.fromJson(item)).toList();

    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YOUR JOBS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return JobCard(history: _history[index]);
        },
      ),
    );
  }
}
