import 'package:flutter/material.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/order_item.dart';
import 'components/product_card.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final List<String> categories = ['All', 'Beverages', 'Snacks', 'Household'];
  int selectedCategory = 0;
  final List<OrderItem> items = [
    const OrderItem(
      name: 'Premium Cola',
      sku: 'BEV-001',
      price: 45,
      image: 'assets/images/cola.png',
      quantity: 2,
    ),
    const OrderItem(
      name: 'Classic Salted Chips',
      sku: 'SNK-042',
      price: 20,
      image: 'assets/images/chips.png',
      quantity: 0,
    ),
    const OrderItem(
      name: 'Hand Wash',
      sku: 'PC-105',
      price: 150,
      image: 'assets/images/handwash.png',
      quantity: 15,
    ),
    const OrderItem(
      name: 'Assorted Biscuits',
      sku: 'SNK-088',
      price: 60,
      image: '',
      quantity: 0,
    ),
  ];

  int get totalItems => items.where((e) => e.quantity > 0).length;
  int get totalAmount => items.fold(0, (sum, e) => sum + e.price * e.quantity);

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF157347)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'New Order',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.sp(context, 20),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sharma General Store',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: AppResponsive.sp(context, 13),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFBDBDBD)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: AppResponsive.r(context, 44),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              itemCount: categories.length,
              separatorBuilder: (context, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(
                  categories[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: AppResponsive.sp(context, 13),
                    color: i == selectedCategory
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
                selected: i == selectedCategory,
                selectedColor: const Color(0xFF157347),
                backgroundColor: Colors.white,
                onSelected: (_) => setState(() => selectedCategory = i),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
              itemCount: items.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) => ProductCard(
                item: items[i],
                onChanged: (q) =>
                    setState(() => items[i] = items[i].copyWith(quantity: q)),
              ),
            ),
          ),
          // Order Summary footer
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: AppResponsive.r(context, 18),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL ORDER',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: AppResponsive.sp(context, 12),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalItems items',
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 15),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ $totalAmount',
                          style: TextStyle(
                            fontSize: AppResponsive.sp(context, 24),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF157347),
                          ),
                        ),
                        Text(
                          'Taxes included',
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: AppResponsive.sp(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.r(context, 16)),
                SizedBox(
                  width: double.infinity,
                  height: AppResponsive.r(context, 52),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF157347),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm Order',
                          style: TextStyle(
                            fontSize: AppResponsive.sp(context, 17),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: AppResponsive.r(context, 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
