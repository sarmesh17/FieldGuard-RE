import 'package:flutter/material.dart';

class VisitStatusCard extends StatelessWidget {
  const VisitStatusCard({super.key});

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
          Row(
            children: [
              const Text(
                'Visit Status',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NOT VISITED TODAY',
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: const [
              Text(
                'Outstanding Balance',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              Spacer(),
              Text(
                '₹ 12,500',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: const [
              Text(
                'Last Visit',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              Spacer(),
              Text(
                'Yesterday, 2:30 PM',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
