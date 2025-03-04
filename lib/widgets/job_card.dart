import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailPage(jobTime: jobTime, pickupLocation: pickupLocation, dropoffLocation: dropoffLocation)),
          );
        },  // Navigate to detailed job view
      ),
    );
  }
}