import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models/cart.dart';
import '../models/product.dart';

/// Cart state backed by /api/cart. Works for guests (session cookie) and users.
class CartStore extends ChangeNotifier {
  Cart cart = Cart.empty();
  bool loading = false;

  int get itemCount => cart.itemCount;
  bool get isEmpty => cart.isEmpty;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.shared.get('/api/cart');
      cart = Cart.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      // leave existing cart; surfaced by callers if needed
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add(Product product, {int quantity = 1}) async {
    final data = await ApiClient.shared.post(
      '/api/cart/items',
      data: {'productID': product.id, 'quantity': quantity},
    );
    cart = Cart.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final data = await ApiClient.shared.patch(
      '/api/cart/items/$itemId',
      data: {'quantity': quantity},
    );
    cart = Cart.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> remove(String itemId) async {
    await ApiClient.shared.delete('/api/cart/items/$itemId');
    await refresh();
  }

  Future<void> clear() async {
    await ApiClient.shared.delete('/api/cart/clear');
    cart = Cart.empty();
    notifyListeners();
  }

  void reset() {
    cart = Cart.empty();
    notifyListeners();
  }
}
