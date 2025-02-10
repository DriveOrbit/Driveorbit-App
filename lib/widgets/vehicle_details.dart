import 'package:flutter/material.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';

class VehicleDetails extends StatelessWidget {
  final VehicleDetailsEntity entity;

  const VehicleDetails({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(9.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 42, 41, 41),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Left Side: Vehicle Icon and Details
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Image.asset(
                    entity.vehicleImage,
                    width: 80,
                  ),
                ), // Vehicle Icon
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 1,
                  height: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 10), // Spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.vehicleModel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      entity.vehicleNumber,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right Side: Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entity.vehicleStatus == 'Available'
                  ? Colors.green
                  : entity.vehicleStatus == 'Booked'
                      ? Colors.orange
                      : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entity.vehicleStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
