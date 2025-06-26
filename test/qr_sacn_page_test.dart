import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveorbit_app/screens/qr_scan/qr_scan_page.dart';

void main() {
  testWidgets('ScanCodePage initializes correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanCodePage(),
      ),
    );

    // Wait for the widget to initialize
    await tester.pump();

    // Check that the page is rendered
    expect(find.byType(ScanCodePage), findsOneWidget);

    // Check for the app bar title
    expect(find.text('Scan QR Code'), findsOneWidget);

    // Check that scaffold is present
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('ScanCodePage has proper structure', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanCodePage(),
      ),
    );

    // Wait for the widget to build
    await tester.pump();

    // Check that essential UI elements are present
    expect(find.byType(ScanCodePage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // The page should have a proper structure regardless of camera state
    expect(find.text('Scan QR Code'), findsOneWidget);
  });
}
