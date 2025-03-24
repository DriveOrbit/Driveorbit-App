import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:driveorbit_app/screens/qr_scan/qr_scan_page.dart';

void main() {
  testWidgets('ScanCodePage has a MobileScanner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanCodePage(),
      ),
    );

    expect(find.byType(MobileScanner), findsOneWidget);
  });
}
