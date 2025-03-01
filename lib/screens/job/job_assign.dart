import 'package:flutter/material.dart';

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

class vehicle_id {
  final String vehicle_id;
  final String vehicle_type;
  final String vehicle_model;
  final String vehicle_number;
  final String vehicle_color;
  final String vehicle_capacity;
  final String vehicle_status;

  vehicle_id({
    required this.vehicle_id,
    required this.vehicle_type,
    required this.vehicle_model,
    required this.vehicle_number,
    required this.vehicle_color,
    required this.vehicle_capacity,
    required this.vehicle_status,
  });
}

class JobCard extends StatelessWidget {
  final String jobTime;
  final String pickupLocation;
  final String dropoffLocation;

  const JobCard({
    super.key,
    required this.jobTime,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(jobTime),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pickupLocation),
            Text(dropoffLocation),
          ],
        ),    
        onTap: () {
          // Navigate to detailed job view
        },
      ),
    );
  }
}
