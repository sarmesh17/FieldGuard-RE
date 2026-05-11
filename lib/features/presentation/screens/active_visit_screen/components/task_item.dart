import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final String label;
  final bool checked;
  final bool highlight;

  const TaskItem({
    super.key,
    required this.label,
    this.checked = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: highlight
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: checked ? const Color(0xFF157347) : const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: highlight
                    ? const Color(0xFF157347)
                    : const Color(0xFF222222),
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
