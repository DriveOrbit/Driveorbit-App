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
    List<Map<String, String>> jobs = [
      {
        'time': '10:30',
        'pickup': 'Main Office (Resort)',
        'dropoff': 'Galle Face'
      },
      {'time': '09:30', 'pickup': 'Bandaranaike Airport', 'dropoff': 'Hotel'}
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Jobs'),
      ),
      body: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return JobCard(
            jobTime: jobs[index]['time']!,
            pickupLocation: jobs[index]['pickup']!,
            dropoffLocation: jobs[index]['dropoff']!,
          );
        },
      ),
    );
  }
}
