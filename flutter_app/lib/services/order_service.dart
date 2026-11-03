import '../api_client.dart';

/// Checkout + payment config.
class OrderService {
  /// GET /api/payments/config → { applicationID, locationID, environment }.
  Future<Map<String, dynamic>> paymentConfig() async {
    final data = await ApiClient.shared.get('/api/payments/config');
    return (data as Map).cast<String, dynamic>();
  }

  /// POST /api/checkout → the created order (the server charges Square, decrements
  /// stock, and clears the cart).
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> body) async {
    final data = await ApiClient.shared.post('/api/checkout', data: body);
    return (data as Map).cast<String, dynamic>();
  }
}
