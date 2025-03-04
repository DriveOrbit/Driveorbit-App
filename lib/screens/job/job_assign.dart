import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/vehicle_model.dart';
import 'package:driveorbit_app/widgets/job_card.dart';

class JobAssignedPage extends StatefulWidget {
  const JobAssignedPage({super.key});

  @override
  _JobAssignedPageState createState() => _JobAssignedPageState();
}

class _JobAssignedPageState extends State<JobAssignedPage> {
  // Add any necessary state variables here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Jobs'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual job count
        itemBuilder: (context, index) {
          return JobCard(
            jobTime: '10:30',
            pickupLocation: 'Main Office (Lesson)',
            dropoffLocation: 'Galle Face',
          );
        },
      ),
    );
  }
}
