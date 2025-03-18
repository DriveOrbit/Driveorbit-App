import 'package:dashboard_ui/screens/vehicle_dasboard/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('Test _buildMetricItem widget', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPage(),
        ),
      ),
    );

    // Verify that the widget displays the correct value and label
    expect(find.text('10.5 KM'), findsOneWidget); // Check for the value
    expect(find.text('Current Mileage'), findsOneWidget); // Check for the label

    // Verify the text styles
    final valueText = tester.widget<Text>(find.text('10.5 KM'));
    expect(valueText.style?.fontSize, 24); // Check font size of the value
    expect(valueText.style?.fontWeight, FontWeight.bold); // Check font weight of the value

    final labelText = tester.widget<Text>(find.text('Current Mileage'));
    expect(labelText.style?.fontSize, 14); // Check font size of the label
    expect(labelText.style?.color, const Color(0xFF6D6BF8)); // Check color of the label
  });
}