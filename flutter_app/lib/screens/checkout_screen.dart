import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../services/auth_service.dart';
import '../services/cart_store.dart';
import '../services/order_service.dart';
import '../theme.dart';
import 'square_card_page.dart';

/// Collects contact + shipping, launches the Square card page, then places the
/// order via POST /api/checkout.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController(text: 'US');
  final _note = TextEditingController();

  bool _placing = false;
  Map<String, dynamic>? _placedOrder;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _name.text = user.name;
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _line1, _line2, _city, _state, _zip, _country, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _email.text.contains('@') &&
      _line1.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _state.text.trim().isNotEmpty &&
      _zip.text.trim().isNotEmpty &&
      _country.text.trim().isNotEmpty;

  Future<void> _startPayment() async {
    final cart = context.read<CartStore>();
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SquareCardPage(displayAmount: cart.cart.formattedSubtotal),
      ),
    );
    if (token == null || !mounted) return; // cancelled
    await _placeOrder(token);
  }

  Future<void> _placeOrder(String sourceId) async {
    setState(() => _placing = true);
    try {
      final order = await OrderService().checkout({
        'sourceID': sourceId,
        'email': _email.text.trim(),
        'customerName': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'shipping': {
          'line1': _line1.text.trim(),
          'line2': _line2.text.trim().isEmpty ? null : _line2.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'postalCode': _zip.text.trim(),
          'country': _country.text.trim(),
        },
        'customerNote': _note.text.trim().isEmpty ? null : _note.text.trim(),
      });
      if (!mounted) return;
      context.read<CartStore>().reset();
      setState(() => _placedOrder = order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Checkout failed')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    return Scaffold(
      appBar: AppBar(title: Text(_placedOrder == null ? 'Checkout' : 'Order Confirmed')),
      body: _placedOrder != null ? _confirmation(_placedOrder!) : _form(cart),
    );
  }

  Widget _form(CartStore cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Contact'),
        _field(_name, 'Full name'),
        _field(_email, 'Email', type: TextInputType.emailAddress),
        _field(_phone, 'Phone (optional)', type: TextInputType.phone),
        _section('Shipping Address'),
        _field(_line1, 'Address line 1'),
        _field(_line2, 'Address line 2 (optional)'),
        _field(_city, 'City'),
        _field(_state, 'State / Province'),
        _field(_zip, 'Postal code'),
        _field(_country, 'Country'),
        _section('Order Note'),
        _field(_note, 'Anything we should know? (optional)', maxLines: 3),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal', style: TextStyle(color: Colors.grey)),
            Text(cart.cart.formattedSubtotal,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Text('Shipping and tax are calculated by the server.',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: NYTheme.pink,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: (!_valid || _placing || cart.isEmpty) ? null : _startPayment,
          child: _placing
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Continue to Payment'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text('Card details are entered securely via Square.',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _confirmation(Map<String, dynamic> order) {
    String money(dynamic v) => '\$${((v is num) ? v.toDouble() : 0.0).toStringAsFixed(2)}';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 12),
        const Center(child: Text('Thank you!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
        Center(child: Text('Order ${order['orderNumber'] ?? ''}', style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow('Subtotal', money(order['subtotal'])),
                _summaryRow('Shipping', money(order['shippingAmount'])),
                _summaryRow('Tax', money(order['taxAmount'])),
                const Divider(),
                _summaryRow('Total', money(order['total']), bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: NYTheme.pink,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Continue Shopping'),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      );

  Widget _field(TextEditingController c, String label,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        autocorrect: type != TextInputType.emailAddress,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
