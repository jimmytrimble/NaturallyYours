import '../api_client.dart';
import '../models/admin_models.dart';
import '../models/conversation.dart';
import '../models/product.dart';

/// Admin API: auth, catalog, orders, messaging inbox, and vending management.
/// Uses the shared cookie-aware [ApiClient], so the admin session authorizes
/// every subsequent request.
class AdminService {
  // Auth
  Future<AdminUser> login(String email, String password) async {
    final data = await ApiClient.shared.loginBasic(
      '/api/auth/admins/login',
      email.trim().toLowerCase(),
      password,
    );
    return AdminUser.fromJson((data as Map<String, dynamic>)['admin'] as Map<String, dynamic>);
  }

  Future<AdminUser?> me() async {
    try {
      final data = await ApiClient.shared.get('/api/auth/admins/me');
      return AdminUser.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.shared.post('/api/auth/admins/logout');
    } catch (_) {}
  }

  // Shopify integration
  Future<bool> shopifyConfigured() async {
    try {
      final data = await ApiClient.shared.get('/api/admin/shopify/status');
      return (data as Map)['configured'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Pulls catalog + inventory from Shopify into the app's DB. Returns {fetched, created, updated}.
  Future<Map<String, dynamic>> shopifySync() async {
    final data = await ApiClient.shared.post('/api/admin/shopify/sync');
    return (data as Map).cast<String, dynamic>();
  }

  Future<AdminStats?> stats() async {
    try {
      final data = await ApiClient.shared.get('/api/admin/stats');
      return AdminStats.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Catalog
  Future<List<Product>> loadAllProducts({bool? active}) async {
    final data = await ApiClient.shared.get('/api/admin/products',
        query: active == null ? null : {'active': active ? 'true' : 'false'});
    return ((data as List?) ?? const [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(Map<String, dynamic> body) async =>
      Product.fromJson(await ApiClient.shared.post('/api/products', data: body) as Map<String, dynamic>);

  Future<Product> updateProduct(String id, Map<String, dynamic> body) async =>
      Product.fromJson(await ApiClient.shared.patch('/api/products/$id', data: body) as Map<String, dynamic>);

  Future<Product> setActive(String id, bool active) async => Product.fromJson(
      await ApiClient.shared.post('/api/products/$id/${active ? 'activate' : 'deactivate'}') as Map<String, dynamic>);

  Future<Product> setFeatured(String id, bool featured) async => Product.fromJson(
      await ApiClient.shared.post('/api/products/$id/${featured ? 'feature' : 'unfeature'}') as Map<String, dynamic>);

  Future<void> deleteProduct(String id) async => ApiClient.shared.delete('/api/products/$id');

  // Orders
  Future<List<AdminOrder>> loadOrders() async {
    final data = await ApiClient.shared.get('/api/admin/orders', query: {'per': '200'});
    final items = ((data as Map)['items'] as List?) ?? const [];
    return items.map((e) => AdminOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminOrder> updateOrderStatus(String id, String status) async => AdminOrder.fromJson(
      await ApiClient.shared.patch('/api/admin/orders/$id/status', data: {'status': status}) as Map<String, dynamic>);

  // Messaging inbox
  Future<List<Conversation>> loadConversations({String? status}) async {
    final data = await ApiClient.shared
        .get('/api/admin/conversations', query: status == null ? null : {'status': status});
    return ((data as List?) ?? const [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> conversation(String id) async =>
      Conversation.fromJson(await ApiClient.shared.get('/api/admin/conversations/$id') as Map<String, dynamic>);

  Future<Conversation> reply(String id, String message) async => Conversation.fromJson(
      await ApiClient.shared.post('/api/admin/conversations/$id/messages', data: {'message': message}) as Map<String, dynamic>);

  Future<void> updateConversation(String id, {String? status, bool? assignToMe}) async {
    await ApiClient.shared.patch('/api/admin/conversations/$id', data: {
      if (status != null) 'status': status,
      if (assignToMe != null) 'assignToMe': assignToMe,
    });
  }

  // Vending
  Future<List<VendingMachine>> loadMachines() async {
    final data = await ApiClient.shared.get('/api/admin/vending/machines');
    return ((data as List?) ?? const [])
        .map((e) => VendingMachine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VendingMachine> machine(String id) async =>
      VendingMachine.fromJson(await ApiClient.shared.get('/api/admin/vending/machines/$id') as Map<String, dynamic>);

  Future<VendingMachine> createMachine(String name, String campus, String? location) async =>
      VendingMachine.fromJson(await ApiClient.shared.post('/api/admin/vending/machines', data: {
        'name': name, 'campus': campus, if (location != null && location.isNotEmpty) 'location': location,
      }) as Map<String, dynamic>);

  Future<void> updateMachine(String id, Map<String, dynamic> body) async =>
      ApiClient.shared.patch('/api/admin/vending/machines/$id', data: body);

  Future<void> deleteMachine(String id) async =>
      ApiClient.shared.delete('/api/admin/vending/machines/$id');

  Future<void> createSlot(String machineId, Map<String, dynamic> body) async =>
      ApiClient.shared.post('/api/admin/vending/machines/$machineId/slots', data: body);

  Future<void> updateSlot(String slotId, Map<String, dynamic> body) async =>
      ApiClient.shared.patch('/api/admin/vending/slots/$slotId', data: body);

  Future<void> deleteSlot(String slotId) async =>
      ApiClient.shared.delete('/api/admin/vending/slots/$slotId');
}
