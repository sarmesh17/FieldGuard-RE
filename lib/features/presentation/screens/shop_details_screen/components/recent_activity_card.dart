import 'package:flutter/material.dart';
import 'activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const ActivityItem(
            icon: Icons.check_circle,
            iconColor: Color(0xFF157347),
            label: 'Visited',
            time: '2 days ago',
          ),
          const SizedBox(height: 10),
          const ActivityItem(
            icon: Icons.payments,
            iconColor: Color(0xFF157347),
            label: 'Payment ₹8,000 collected',
            time: '2 days ago',
          ),
          const SizedBox(height: 10),
          const ActivityItem(
            icon: Icons.cancel,
            iconColor: Color(0xFF6B7280),
            label: 'No visit',
            time: '3 days ago',
          ),
        ],
      ),
    );
  }
}
