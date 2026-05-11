import 'package:flutter/material.dart';

class MapMarker extends StatelessWidget {
  final int number;
  final bool isCurrent;

  const MapMarker({super.key, required this.number, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF157347) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF157347), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: isCurrent ? Colors.white : const Color(0xFF157347),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
