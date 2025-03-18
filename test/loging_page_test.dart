import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/screens/auth/login_page.dart';

void main() {
  testWidgets('Login Page displays correctly', (WidgetTester tester) async {
    // Build the LoginPage and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify that the Login Page displays the expected text.

    expect(find.text('Enter your company ID to get started:'), findsOneWidget);
    expect(find.text('Enter your password:'), findsOneWidget);
    expect(find.text('Let\'s Drive!'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Verify that the Login Page displays the expected widgets.
    expect(find.byType(TextField),
        findsNWidgets(2)); // Two TextFields: Company ID and Password
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
