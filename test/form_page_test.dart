import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/Screens/form/page2.dart';

void main() {
  group('MileageForm Widget Tests', () {
    testWidgets('Mileage TextField should accept input',
        (WidgetTester tester) async {
      // Set a large screen size to prevent overflow
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: MileageForm()));

      // Enter text in the TextField
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      // Verify that the text was entered
      expect(find.text('12345'), findsOneWidget);

      // Reset the screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('Camera button should be tappable',
        (WidgetTester tester) async {
      // Set a large screen size to prevent overflow
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: MileageForm()));

      // Verify camera button is present
      expect(find.text('Take a photo of dashboard'), findsOneWidget);

      // Tap the camera section
      await tester.tap(
        find.ancestor(
          of: find.text('Take a photo of dashboard'),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      // Reset the screen size
      addTearDown(tester.view.reset);
    });
  });
}
