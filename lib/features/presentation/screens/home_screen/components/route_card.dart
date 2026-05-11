import 'package:flutter/material.dart';
import '../../../../../core/theme/app_responsive.dart';

class RouteCard extends StatelessWidget {
  final int index;
  final String shopName;
  final String address;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String distance;
  final bool isActive;

  const RouteCard({
    super.key,
    required this.index,
    required this.shopName,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.distance,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(AppResponsive.r(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border(left: BorderSide(color: statusColor, width: 6))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AppResponsive.r(context, 20),
            backgroundColor: isActive ? statusColor : const Color(0xFFE5E7EB),
            child: Text(
              '$index',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.sp(context, 14),
              ),
            ),
          ),
          SizedBox(width: AppResponsive.r(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 17),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 13),
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppResponsive.r(context, 15),
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        distance,
                        style: TextStyle(
                          fontSize: AppResponsive.sp(context, 12),
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.r(context, 10),
              vertical: AppResponsive.r(context, 5),
            ),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.sp(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
