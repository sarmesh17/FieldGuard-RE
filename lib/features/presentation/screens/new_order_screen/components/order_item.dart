class OrderItem {
  final String name;
  final String sku;
  final int price;
  final String image;
  final int quantity;

  const OrderItem({
    required this.name,
    required this.sku,
    required this.price,
    required this.image,
    required this.quantity,
  });

  OrderItem copyWith({
    String? name,
    String? sku,
    int? price,
    String? image,
    int? quantity,
  }) {
    return OrderItem(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
    );
  }
}
