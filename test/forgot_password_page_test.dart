import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/screens/auth/forgot_password_page.dart';

void main() {
  testWidgets('Forgot Password Page displays correctly',
      (WidgetTester tester) async {
    // Build the ForgotPasswordPage and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));

    // Verify that the Forgot Password Page displays the expected text.

    expect(find.text('Enter your company ID'), findsOneWidget);
    expect(find.text('Get Password'), findsOneWidget);
    expect(find.text('Do you know password?'), findsOneWidget);

    // Verify that the Forgot Password Page displays the expected widgets.
    expect(
        find.byType(TextField), findsOneWidget); // One TextField for Company ID
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
