import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';

/// Admin order log with status management.
class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  List<AdminOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await widget.service.loadOrders();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = _orders[i];
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(o.money(o.total)),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(o.customerName, overflow: TextOverflow.ellipsis)),
                _StatusTag(status: o.status),
              ],
            ),
            onTap: () async {
              final updated = await Navigator.of(context).push<AdminOrder>(MaterialPageRoute(
                builder: (_) => _OrderDetail(service: widget.service, order: o),
              ));
              if (updated != null) {
                setState(() => _orders[i] = updated);
              }
            },
          );
        },
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final String status;

  Color get _color => switch (status) {
        'paid' => Colors.green,
        'fulfilled' => NYTheme.pink,
        'pending_payment' => Colors.orange,
        'cancelled' || 'refunded' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(20)),
      child: Text(orderStatusLabel(status),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _OrderDetail extends StatefulWidget {
  const _OrderDetail({required this.service, required this.order});
  final AdminService service;
  final AdminOrder order;

  @override
  State<_OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<_OrderDetail> {
  late AdminOrder _order;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _setStatus(String status) async {
    if (status == _order.status || _order.id == null) return;
    setState(() => _updating = true);
    try {
      _order = await widget.service.updateOrderStatus(_order.id!, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not update')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(title: Text(o.orderNumber)),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(_order);
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('Status: '),
                _updating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : DropdownButton<String>(
                        value: o.status,
                        items: [
                          for (final s in orderStatuses)
                            DropdownMenuItem(value: s, child: Text(orderStatusLabel(s))),
                        ],
                        onChanged: (v) { if (v != null) _setStatus(v); },
                      ),
              ],
            ),
            const Divider(),
            Text('Customer', style: _h()),
            Text('${o.customerName}\n${o.email}'),
            const SizedBox(height: 12),
            Text('Items', style: _h()),
            for (final it in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${it.productName}  ×${it.quantity}')),
                    Text(o.money(it.lineTotal)),
                  ],
                ),
              ),
            const Divider(),
            _row('Subtotal', o.money(o.subtotal)),
            _row('Shipping', o.money(o.shippingAmount)),
            _row('Tax', o.money(o.taxAmount)),
            _row('Total', o.money(o.total), bold: true),
            const SizedBox(height: 12),
            Text('Ship To', style: _h()),
            Text(o.shippingLines.join('\n')),
          ],
        ),
      ),
    );
  }

  TextStyle _h() => const TextStyle(fontWeight: FontWeight.w600, fontSize: 16);

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: const TextStyle(color: Colors.grey)),
            Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}
