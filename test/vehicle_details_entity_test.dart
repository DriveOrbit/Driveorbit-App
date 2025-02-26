import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleDetailsEntity', () {
    test('fromJson should parse JSON correctly', () {
      final json = {
        'vehicleId': 12,
        'vehicleNumber': 'KY-7766',
        'vehicleType': 'Car',
        'vehicleModel': 'Nissan Sunny (1997)',
        'vehicleImage': 'assets/car.png',
        'vehicleStatus': 'Available',
      };

      final vehicle = VehicleDetailsEntity.fromJson(json);

      expect(vehicle.vehicleId, 12);
      expect(vehicle.vehicleNumber, 'KY-7766');
      expect(vehicle.vehicleType, 'Car');
      expect(vehicle.vehicleModel, 'Nissan Sunny (1997)');
      expect(vehicle.vehicleImage, 'assets/car.png');
      expect(vehicle.vehicleStatus, 'Available');
    });
  });
}