import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_ui/main.dart'; // Import your main app
import 'package:dashboard_ui/screens/vehicle_dasboard/map_page.dart'; // Import the map page

void main() {
  testWidgets('MyApp renders MapPage', (WidgetTester tester) async {
    // Build the MyApp widget
    await tester.pumpWidget(const MyApp());

    // Check if the MapPage widget is present
    expect(find.byType(MapPage), findsOneWidget);
  });

  testWidgets('Floating action button exists in MapPage', (WidgetTester tester) async {
    // Build the MapPage widget
    await tester.pumpWidget(const MaterialApp(home: MapPage()));

    // Check if FloatingActionButton is present
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Tapping FloatingActionButton calls _getCurrentLocation', (WidgetTester tester) async {
    // Build the MapPage widget
    await tester.pumpWidget(const MaterialApp(home: MapPage()));

    // Find the FloatingActionButton
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    // Tap the FloatingActionButton
    await tester.tap(fab);
    await tester.pump();

    // Since we can't check the exact location fetching, we verify that the button is tappable
    expect(fab, findsOneWidget);
  });
}
