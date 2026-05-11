import 'package:flutter/material.dart';
import 'task_item.dart';

class VisitTasksCard extends StatelessWidget {
  const VisitTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF157347)),
              SizedBox(width: 8),
              Text(
                'Visit Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Text(
                '1 of 5 done',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TaskItem(
            label: 'Check in verified (NFC)',
            checked: true,
            highlight: true,
          ),
          const TaskItem(label: 'Discuss new products'),
          const TaskItem(label: 'Take order'),
          const TaskItem(label: 'Collect payment'),
          const TaskItem(label: 'Take shop photo'),
        ],
      ),
    );
  }
}
