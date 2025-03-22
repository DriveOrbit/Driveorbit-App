import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';

class VehicleDetailModal extends StatelessWidget {
  final VehicleDetailsEntity vehicle;

  const VehicleDetailModal({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Vehicle basic info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle image
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(15.r),
                ),
                padding: EdgeInsets.all(10.r),
                child: Image.asset(
                  vehicle.vehicleImage,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 16.w),

              // Vehicle details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model and QR code row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.vehicleModel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (vehicle.qrCodeURL.isNotEmpty)
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: vehicle.qrCodeURL.isNotEmpty
                                ? Image.network(vehicle.qrCodeURL)
                                : const Icon(Icons.qr_code,
                                    color: Colors.black),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // License plate
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        vehicle.plateNumber.isNotEmpty
                            ? vehicle.plateNumber
                            : vehicle.vehicleNumber,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Status badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: vehicle.vehicleStatus == 'Available'
                            ? Colors.green
                            : vehicle.vehicleStatus == 'Booked'
                                ? Colors.orange
                                : Colors.red,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        vehicle.vehicleStatus,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Specs section
          Text(
            "Vehicle Specifications",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),

          // Specs grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            children: [
              _buildSpecItem(Icons.local_gas_station, "Fuel Type",
                  vehicle.fuelType.isNotEmpty ? vehicle.fuelType : "Unknown"),
              _buildSpecItem(
                  Icons.speed,
                  "Consumption",
                  vehicle.fuelConsumption > 0
                      ? "${vehicle.fuelConsumption} L/km"
                      : "N/A"),
              _buildSpecItem(
                  Icons.settings,
                  "Transmission",
                  vehicle.gearSystem.isNotEmpty
                      ? vehicle.gearSystem
                      : "Manual"),
              _buildSpecItem(Icons.medical_services, "Emergency Kit",
                  vehicle.hasEmergencyKit ? "Available" : "N/A"),
            ],
          ),

          SizedBox(height: 20.h),

          // Condition and warnings
          if (vehicle.condition.isNotEmpty)
            _buildInfoSection(
              "Condition",
              vehicle.condition,
              color: _getConditionColor(vehicle.condition),
            ),

          if (vehicle.warnings.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                _buildInfoSection(
                  "Warnings",
                  vehicle.warnings,
                  color: Colors.amber,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),

          SizedBox(height: 24.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Add navigation to a detailed dedicated page if needed
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text("Open Full Details"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Only show book button if available
              if (vehicle.vehicleStatus == 'Available')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Add booking functionality
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Book Vehicle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D6BF8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build specification items
  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build information sections
  Widget _buildInfoSection(String title, String content,
      {Color? color, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10.r),
        border: color != null ? Border.all(color: color, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color ?? Colors.white, size: 16.sp),
                SizedBox(width: 6.w),
              ],
              Text(
                title,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Get color based on vehicle condition
  Color _getConditionColor(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('excellent') || condition.contains('good')) {
      return Colors.green;
    } else if (condition.contains('fair') || condition.contains('average')) {
      return Colors.orange;
    } else if (condition.contains('poor') || condition.contains('bad')) {
      return Colors.red;
    }
    return Colors.blue;
  }
}
