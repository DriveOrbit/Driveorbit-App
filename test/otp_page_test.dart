import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/screens/auth/otp_page.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:slide_countdown/slide_countdown.dart';

void main() {
  testWidgets('OTP Page displays correctly', (WidgetTester tester) async {
    // Build the OtpPage and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: OtpPage()));
    expect(find.text("Didn't receive the OTP?"), findsOneWidget);

    // Verify that the OTP Page displays the expected widgets.
    expect(find.byType(OtpTextField), findsOneWidget);
    expect(find.byType(SlideCountdownSeparated), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
