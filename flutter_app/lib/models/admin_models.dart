/// Admin-side models mirroring the server DTOs.

class AdminUser {
  AdminUser({required this.name, required this.email, required this.role});
  final String name;
  final String email;
  final String role; // super_admin | moderator | support

  bool get canManageCatalog => role != 'support';
  String get roleDisplay => switch (role) {
        'super_admin' => 'Super Admin',
        'moderator' => 'Moderator',
        'support' => 'Support',
        _ => role,
      };

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'support') as String,
      );
}

class AdminStats {
  AdminStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.orders,
    required this.users,
    required this.openConversations,
  });
  final int totalProducts, activeProducts, orders, users, openConversations;

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    int v(String k) => (j[k] is num) ? (j[k] as num).toInt() : 0;
    return AdminStats(
      totalProducts: v('totalProducts'),
      activeProducts: v('activeProducts'),
      orders: v('orders'),
      users: v('users'),
      openConversations: v('openConversations'),
    );
  }
}

class AdminOrderItem {
  AdminOrderItem({required this.productName, required this.quantity, required this.lineTotal});
  final String productName;
  final int quantity;
  final double lineTotal;
  factory AdminOrderItem.fromJson(Map<String, dynamic> j) => AdminOrderItem(
        productName: (j['productName'] ?? '') as String,
        quantity: (j['quantity'] ?? 0) as int,
        lineTotal: (j['lineTotal'] is num) ? (j['lineTotal'] as num).toDouble() : 0,
      );
}

class AdminOrder {
  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.email,
    required this.total,
    required this.subtotal,
    required this.shippingAmount,
    required this.taxAmount,
    required this.status,
    required this.items,
    required this.shippingLines,
  });

  final String? id;
  final String orderNumber;
  final String customerName;
  final String email;
  final double total, subtotal, shippingAmount, taxAmount;
  final String status;
  final List<AdminOrderItem> items;
  final List<String> shippingLines;

  String money(double v) => '\$${v.toStringAsFixed(2)}';

  factory AdminOrder.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] is num) ? (j[k] as num).toDouble() : 0;
    final ship = <String>[
      (j['shippingLine1'] ?? '') as String,
      if ((j['shippingLine2'] ?? '').toString().isNotEmpty) j['shippingLine2'] as String,
      '${j['shippingCity'] ?? ''}, ${j['shippingState'] ?? ''} ${j['shippingPostalCode'] ?? ''}',
      (j['shippingCountry'] ?? '') as String,
    ]..removeWhere((s) => s.trim().isEmpty || s.trim() == ',');
    return AdminOrder(
      id: j['id'] as String?,
      orderNumber: (j['orderNumber'] ?? '') as String,
      customerName: (j['customerName'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      total: d('total'),
      subtotal: d('subtotal'),
      shippingAmount: d('shippingAmount'),
      taxAmount: d('taxAmount'),
      status: (j['status'] ?? '') as String,
      items: ((j['items'] as List?) ?? const [])
          .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingLines: ship,
    );
  }
}

const orderStatuses = ['pending_payment', 'paid', 'fulfilled', 'cancelled', 'refunded'];
String orderStatusLabel(String s) => switch (s) {
      'pending_payment' => 'Pending Payment',
      'paid' => 'Paid',
      'fulfilled' => 'Fulfilled',
      'cancelled' => 'Cancelled',
      'refunded' => 'Refunded',
      _ => s,
    };

class VendingSlot {
  VendingSlot({
    required this.id,
    required this.slotNumber,
    required this.productName,
    required this.onHand,
    required this.hold,
  });
  final String? id;
  final int slotNumber;
  final String productName;
  final int onHand;
  final int hold;

  bool get needsRestock => onHand < hold;

  factory VendingSlot.fromJson(Map<String, dynamic> j) => VendingSlot(
        id: j['id'] as String?,
        slotNumber: (j['slotNumber'] ?? 0) as int,
        productName: (j['productName'] ?? '') as String,
        onHand: (j['onHand'] ?? 0) as int,
        hold: (j['hold'] ?? 0) as int,
      );
}

class VendingMachine {
  VendingMachine({
    required this.id,
    required this.name,
    required this.campus,
    required this.location,
    required this.slotCount,
    required this.needsRestockCount,
    required this.slots,
  });
  final String? id;
  final String name;
  final String campus;
  final String? location;
  final int slotCount;
  final int needsRestockCount;
  final List<VendingSlot> slots;

  factory VendingMachine.fromJson(Map<String, dynamic> j) => VendingMachine(
        id: j['id'] as String?,
        name: (j['name'] ?? '') as String,
        campus: (j['campus'] ?? '') as String,
        location: j['location'] as String?,
        slotCount: (j['slotCount'] ?? 0) as int,
        needsRestockCount: (j['needsRestockCount'] ?? 0) as int,
        slots: ((j['slots'] as List?) ?? const [])
            .map((e) => VendingSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
