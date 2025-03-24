import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceIndicator extends StatelessWidget {
  final String title;
  final String status;
  final String date;
  final Color statusColor;
  final double percentage; // Add percentage property

  const MaintenanceIndicator({
    super.key,
    required this.title,
    required this.status,
    required this.date,
    required this.statusColor,
    required this.percentage, // Make percentage required
  });

  // Helper method to determine color based on percentage
  static Color getColorForPercentage(double percentage) {
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 50) return Colors.purple;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }

  // Helper method to calculate percentage based on date
  static double calculatePercentage(String lastCheckDate, int recommendedDays) {
    try {
      // If no date or invalid format, return 0%
      if (lastCheckDate.isEmpty || lastCheckDate == 'Please check it') {
        return 0;
      }

      // Handle "Last week" type text
      if (lastCheckDate == 'Last week') {
        return 75; // Assume 75% for last week
      }

      // Parse the date
      DateTime checkDate;
      try {
        checkDate = DateFormat('dd/MM/yyyy').parse(lastCheckDate);
      } catch (e) {
        // Try another format if the first one fails
        try {
          checkDate = DateFormat('MM/dd/yyyy').parse(lastCheckDate);
        } catch (e) {
          return 0; // Return 0 if date parsing fails
        }
      }

      // Calculate days since last check
      final now = DateTime.now();
      final daysSinceCheck = now.difference(checkDate).inDays;

      // Calculate percentage (100% when fresh, 0% when past recommended days)
      double calculatedPercentage =
          100 - (daysSinceCheck / recommendedDays * 100);

      // Clamp between 0 and 100
      return calculatedPercentage.clamp(0, 100);
    } catch (e) {
      print('Error calculating percentage: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, // Increased container width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background circle (gray)
              Container(
                width: 100, // Increased from 80
                height: 100, // Increased from 80
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 10, // Increased from 8
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 100, // Increased from 80
                height: 100, // Increased from 80
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10, // Increased from 8
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              // Inner circle with text
              Container(
                width: 85, // Increased from 70
                height: 85, // Increased from 70
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: statusColor.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14, // Increased from 12
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11, // Increased from 10
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Increased from 8
          Text(
            title,
            style: const TextStyle(
              fontSize: 13, // Increased from 12
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
