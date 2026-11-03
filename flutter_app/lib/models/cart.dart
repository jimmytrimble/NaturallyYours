import 'product.dart';

/// Mirrors the server `CartItemDTO`.
class CartItem {
  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.lineTotal,
  });

  final String? id;
  final Product product;
  final int quantity;
  final double lineTotal;

  String get formattedLineTotal => '\$${lineTotal.toStringAsFixed(2)}';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return CartItem(
      id: json['id'] as String?,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] ?? 0) as int,
      lineTotal: toDouble(json['lineTotal']),
    );
  }
}

/// Mirrors the server `CartDTO`.
class Cart {
  Cart({
    required this.items,
    required this.subtotal,
    required this.itemCount,
  });

  final List<CartItem> items;
  final double subtotal;
  final int itemCount;

  bool get isEmpty => items.isEmpty;
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  factory Cart.empty() => Cart(items: const [], subtotal: 0, itemCount: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final items = ((json['items'] as List?) ?? const [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return Cart(
      items: items,
      subtotal: toDouble(json['subtotal']),
      itemCount: (json['itemCount'] ?? 0) as int,
    );
  }
}
