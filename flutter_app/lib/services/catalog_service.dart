import '../api_client.dart';
import '../models/product.dart';

/// Loads the public product catalog from the API.
class CatalogService {
  CatalogService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/products (paginated envelope: { items, metadata }).
  Future<List<Product>> loadProducts() async {
    final json = await _client.getJson('/api/products', query: {'per': '200'});
    final items = (json?['items'] as List?) ?? const [];
    return items
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products/featured (admin-curated best sellers).
  Future<List<Product>> loadFeatured() async {
    final json = await _client.getJson('/api/products/featured');
    final list = (json as List?) ?? const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Distinct categories, in a store-friendly order.
  List<String> categories(List<Product> products) {
    const preferred = ['Bundles', 'Skincare', 'Haircare', 'Treatments', 'Men'];
    final present = products.map((p) => p.category).toSet();
    final ordered = preferred.where(present.contains).toList();
    final extras = present.difference(preferred.toSet()).toList()..sort();
    return [...ordered, ...extras];
  }
}
