import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driveorbit_app/models/vehicle_details_entity.dart';
import 'package:driveorbit_app/services/scan_service.dart';
import 'dart:async';

class VehicleDetailModal extends StatefulWidget {
  final VehicleDetailsEntity vehicle;

  const VehicleDetailModal({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailModal> createState() => _VehicleDetailModalState();
}

class _VehicleDetailModalState extends State<VehicleDetailModal> {
  // State variables
  bool _isProcessing = false;
  bool _hasProcessed = false;
  String? _jobId;

  // Service
  final ScanService _scanService = ScanService();

  @override
  void initState() {
    super.initState();
    // Generate the job ID for reference
    _jobId = _scanService.generateJobId(widget.vehicle.vehicleId.toString());
    // Check if job already exists when modal opens
    _checkExistingJob();
  }

  // Check if job already exists
  Future<void> _checkExistingJob() async {
    try {
      final exists = await _scanService
          .checkJobExists(widget.vehicle.vehicleId.toString());
      if (exists && mounted) {
        setState(() {
          _hasProcessed = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking job status: $e');
    }
  }

  // Process QR scan
  Future<void> _processQrScan() async {
    if (_isProcessing || _hasProcessed) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Wait a bit to prevent button double-press
      await Future.delayed(const Duration(milliseconds: 300));

      // Create the job
      final result = await _scanService.createJob(widget.vehicle);

      if (mounted) {
        setState(() {
          _hasProcessed = true;
          _isProcessing = false;
          _jobId = result['jobId'];
        });

        // Show message based on result
        final snackColor = result['success'] ? Colors.green : Colors.orange;
        final message = result['message'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message +
                (result['jobId'] != null ? ' (ID: ${result['jobId']})' : '')),
            backgroundColor: snackColor,
          ),
        );

        // Close modal on success with slight delay for better UX
        if (result['success']) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                  widget.vehicle.vehicleImage,
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
                            widget.vehicle.vehicleModel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.vehicle.qrCodeURL.isNotEmpty)
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: _hasProcessed
                                  ? Border.all(color: Colors.green, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Base content - QR code or status
                                if (_isProcessing)
                                  const CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  )
                                else if (_hasProcessed)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green)
                                else
                                  GestureDetector(
                                    onTap: _processQrScan,
                                    child: widget.vehicle.qrCodeURL.isNotEmpty
                                        ? Image.network(
                                            widget.vehicle.qrCodeURL,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(Icons.qr_code,
                                                  color: Colors.black);
                                            },
                                          )
                                        : const Icon(Icons.qr_code,
                                            color: Colors.black),
                                  ),

                                // Add an indicator badge for processed state
                                if (_hasProcessed)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12.w,
                                      height: 12.h,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                        widget.vehicle.plateNumber.isNotEmpty
                            ? widget.vehicle.plateNumber
                            : widget.vehicle.vehicleNumber,
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
                        color: widget.vehicle.vehicleStatus == 'Available'
                            ? Colors.green
                            : widget.vehicle.vehicleStatus == 'Booked'
                                ? Colors.orange
                                : Colors.red,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        widget.vehicle.vehicleStatus,
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
              _buildSpecItem(
                  Icons.local_gas_station,
                  "Fuel Type",
                  widget.vehicle.fuelType.isNotEmpty
                      ? widget.vehicle.fuelType
                      : "Unknown"),
              _buildSpecItem(
                  Icons.speed,
                  "Consumption",
                  widget.vehicle.fuelConsumption > 0
                      ? "${widget.vehicle.fuelConsumption} L/km"
                      : "N/A"),
              _buildSpecItem(
                  Icons.settings,
                  "Transmission",
                  widget.vehicle.gearSystem.isNotEmpty
                      ? widget.vehicle.gearSystem
                      : "Manual"),
              _buildSpecItem(Icons.medical_services, "Emergency Kit",
                  widget.vehicle.hasEmergencyKit ? "Available" : "N/A"),
            ],
          ),

          SizedBox(height: 20.h),

          // Condition and warnings
          if (widget.vehicle.condition.isNotEmpty)
            _buildInfoSection(
              "Condition",
              widget.vehicle.condition,
              color: _getConditionColor(widget.vehicle.condition),
            ),

          if (widget.vehicle.warnings.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                _buildInfoSection(
                  "Warnings",
                  widget.vehicle.warnings,
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
              if (widget.vehicle.vehicleStatus == 'Available')
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
