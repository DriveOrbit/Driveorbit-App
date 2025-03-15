import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';
import 'package:driveorbit_app/widgets/job_card.dart';
import 'package:intl/intl.dart';

void main() {
  // Sample test data
  final testJob = JobDetailsEntity(
    historyId: 'H001',
    date: DateTime(2024, 11, 11),
    arrivedTime: DateTime(2024, 11, 11, 8, 30),
    distance: 157.0,
    duration: const Duration(minutes: 120),
    startLocation: 'Colombo City Center',
    endLocation: 'Katunayake Airport',
  );

  testWidgets('JobCard renders correctly with given data', (WidgetTester tester) async {
    // Build the JobCard widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(history: testJob),
        ),
      ),
    );

    // Verify the date is displayed correctly
    expect(find.text(DateFormat('MMM dd, yyyy').format(testJob.date)), findsOneWidget);

    // Verify the arrived time is displayed correctly
    expect(find.text('Arrived: ${DateFormat('hh:mm a').format(testJob.arrivedTime)}'), findsOneWidget);

    // Verify the start and end locations are displayed
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text(testJob.startLocation), findsOneWidget);
    expect(find.text(testJob.endLocation), findsOneWidget);

    // Verify the distance and duration are displayed
    expect(find.text('157.0 km'), findsOneWidget);
    expect(find.text('2h 0m'), findsOneWidget);

    // Verify the contact button is displayed
    expect(find.text('Contact'), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);

    // Verify the arrow icon is displayed
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    // Verify the location icons are displayed
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
  });

  testWidgets('JobCard handles long location names correctly', (WidgetTester tester) async {
    // Test data with long location names
    final longLocationJob = JobDetailsEntity(
      historyId: 'H002',
      date: DateTime(2024, 11, 10),
      arrivedTime: DateTime(2024, 11, 10, 9, 15),
      distance: 89.5,
      duration: const Duration(minutes: 90),
      startLocation: 'Very Long Starting Location Name That Might Wrap',
      endLocation: 'Extremely Long Destination Name That Should Definitely Wrap to Multiple Lines',
    );

    // Build the JobCard widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(history: longLocationJob),
        ),
      ),
    );

    // Verify long location names are displayed (with ellipsis if truncated)
    expect(find.text(longLocationJob.startLocation), findsOneWidget);
    expect(find.text(longLocationJob.endLocation), findsOneWidget);

    // Verify the layout doesn't break
    expect(find.byType(JobCard), findsOneWidget);
  });
}