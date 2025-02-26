import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/widgets/vehicle_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VehicleDetails widget should display vehicle details correctly',
      (WidgetTester tester) async {
    final vehicle = VehicleDetailsEntity(
      vehicleId: 12,
      vehicleNumber: 'KY-7766',
      vehicleType: 'Car',
      vehicleModel: 'Nissan Sunny (1997)',
      vehicleImage: 'assets/car.png',
      vehicleStatus: 'Available',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleDetails(entity: vehicle),
        ),
      ),
    );

    expect(find.text('Nissan Sunny (1997)'), findsOneWidget);
    expect(find.text('KY-7766'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });
}
