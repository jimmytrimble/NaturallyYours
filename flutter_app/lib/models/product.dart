import '../api_client.dart';

/// Mirrors the server `ProductDTO` (camelCase JSON).
class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.effectivePrice,
    required this.category,
    required this.inStock,
    required this.onSale,
    required this.imageUrls,
    this.salePrice,
    this.sku,
    this.isFeatured = false,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final double effectivePrice;
  final String category;
  final bool inStock;
  final bool onSale;
  final bool isFeatured;
  final List<String> imageUrls;
  final String? sku;
  final List<String> tags;

  String? get primaryImageUrl =>
      imageUrls.isEmpty ? null : ApiClient.imageUrl(imageUrls.first);

  String get formattedPrice => '\$${effectivePrice.toStringAsFixed(2)}';
  String get formattedOriginalPrice => '\$${price.toStringAsFixed(2)}';

  factory Product.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return Product(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      price: toDouble(json['price']),
      salePrice: json['salePrice'] == null ? null : toDouble(json['salePrice']),
      effectivePrice: toDouble(json['effectivePrice']),
      category: (json['category'] ?? '') as String,
      inStock: (json['inStock'] ?? false) as bool,
      onSale: (json['onSale'] ?? false) as bool,
      isFeatured: (json['isFeatured'] ?? false) as bool,
      imageUrls: ((json['imageURLs'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      sku: json['sku'] as String?,
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
