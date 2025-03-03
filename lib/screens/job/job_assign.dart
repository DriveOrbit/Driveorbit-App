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

class VehicleId {
  final String vehicleId;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final String vehicleColor;
  final String vehicleCapacity;
  final String vehicleStatus;

  vehicleId({
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.vehicleColor,
    required this.vehicleCapacity,
    required this.vehicleStatus,
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
        leading: Icon(Icons.work), //adding an icon for jobs
        title: Text(jobTime),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children:[Icon(Icons.location_on,SizedBox(width:5),Text(pickupLocation)]),
            Row(children:[Icon(Icons.flag),SizedBox(width:5),Text(dropoffLocation)]),
          ],
        ),
        onTap: () {
          // Navigate to detailed job view
        },
      ),
    );
  }
}
