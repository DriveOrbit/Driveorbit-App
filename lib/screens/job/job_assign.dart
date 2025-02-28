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
        **theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light, // Light theme
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark, // Dark theme
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark, // Set to ThemeMode.dark for dark theme
        home: JobAssignedPage(), // Navigate to job view**
        onTap: () {
          // Navigate to detailed job view
        },
      ),
    );
  }
}
