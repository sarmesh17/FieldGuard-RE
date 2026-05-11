import 'package:flutter/material.dart';
import 'check_in_option.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key});

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
            'Check In to This Shop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          const Text(
            'Choose your verification method',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          CheckInOption(
            icon: Icons.nfc,
            label: 'Tap NFC Sticker',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          CheckInOption(
            icon: Icons.qr_code,
            label: 'Scan QR Code',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          CheckInOption(
            icon: Icons.sms,
            label: 'Request OTP via SMS',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
