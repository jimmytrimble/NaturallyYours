import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models/product.dart';

/// Wishlist state backed by /api/favorites (authenticated users only).
class FavoritesStore extends ChangeNotifier {
  List<Product> favorites = [];
  bool loading = false;

  bool get isEmpty => favorites.isEmpty;

  bool isFavorite(Product p) => favorites.any((f) => f.id == p.id);

  /// GET /api/favorites → { favorites: [{ id, product }], count }. Clears on 401 (guest).
  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.shared.get('/api/favorites');
      final list = ((data as Map)['favorites'] as List?) ?? const [];
      favorites = list
          .map((e) => Product.fromJson((e as Map<String, dynamic>)['product'] as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.isUnauthorized) favorites = [];
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  Future<void> add(Product p) async {
    await ApiClient.shared.post('/api/favorites', data: {'productID': p.id});
    await refresh();
  }

  Future<void> remove(Product p) async {
    await ApiClient.shared.delete('/api/favorites/product/${p.id}');
    favorites.removeWhere((f) => f.id == p.id);
    notifyListeners();
  }

  Future<void> toggle(Product p) async {
    if (isFavorite(p)) {
      await remove(p);
    } else {
      await add(p);
    }
  }

  void reset() {
    favorites = [];
    notifyListeners();
  }
}
