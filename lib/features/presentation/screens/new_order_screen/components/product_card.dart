import 'package:flutter/material.dart';
import '../../../../../core/theme/app_responsive.dart';
import 'order_item.dart';
import 'quantity_selector.dart';

class ProductCard extends StatelessWidget {
  final OrderItem item;
  final ValueChanged<int> onChanged;

  const ProductCard({super.key, required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final imgSize = AppResponsive.r(context, 54);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: item.quantity > 0
            ? const Border(
                left: BorderSide(color: Color(0xFF157347), width: 5),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 12),
        vertical: AppResponsive.r(context, 10),
      ),
      child: Row(
        children: [
          Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.image.isNotEmpty
                ? Image.asset(item.image, fit: BoxFit.contain)
                : Icon(
                    Icons.image,
                    color: const Color(0xFFBDBDBD),
                    size: AppResponsive.r(context, 30),
                  ),
          ),
          SizedBox(width: AppResponsive.r(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Let the name wrap naturally rather than truncating
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${item.sku}',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: AppResponsive.sp(context, 12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${item.price} / piece',
                  style: TextStyle(
                    color: const Color(0xFF157347),
                    fontWeight: FontWeight.w600,
                    fontSize: AppResponsive.sp(context, 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppResponsive.r(context, 8)),
          QuantitySelector(quantity: item.quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}
