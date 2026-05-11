import 'package:flutter/material.dart';

class CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleAction({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFD1FADF),
        child: Icon(icon, color: const Color(0xFF157347), size: 28),
      ),
    );
  }
}
