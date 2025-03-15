import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveorbit_app/models/job_details_entity.dart';

class JobCard extends StatelessWidget {
  final JobDetailsEntity history;

  const JobCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(166, 107, 101, 101).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(history.date),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                'Arrived: ${DateFormat('hh:mm a').format(history.arrivedTime)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                  Icons.location_on, "From", history.startLocation),
              const Icon(Icons.arrow_forward,
                  color: Color.fromARGB(255, 255, 255, 255)),
              _buildInfoColumn(Icons.location_pin, "To", history.endLocation),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMetricItem(
                    Icons.directions_car,
                    "${history.distance.toStringAsFixed(1)} km",
                  ),
                  const SizedBox(width: 20),
                  _buildMetricItem(
                    Icons.access_time,
                    "${history.duration.inHours}h ${history.duration.inMinutes.remainder(60)}m",
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(180, 27, 27, 127),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Add contact functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
