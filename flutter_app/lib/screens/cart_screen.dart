import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../services/cart_store.dart';
import '../theme.dart';
import 'checkout_screen.dart';

/// Cart tab: line items with quantity steppers, subtotal, and a checkout button.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartStore>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CartStore>();

    if (store.loading && store.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.isEmpty) {
      return _empty();
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Cart', style: NYTheme.screenTitle),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: store.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in store.cart.items) _row(context, item),
              ],
            ),
          ),
        ),
        _checkoutBar(context, store),
      ],
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Your Cart is Empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Browse the shop and add products you love.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _row(BuildContext context, CartItem item) {
    final store = context.read<CartStore>();
    final img = item.product.primaryImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: img == null
                    ? Container(color: const Color(0xFFF0F0F0), child: const Icon(Icons.photo, color: Colors.black26))
                    : Image.network(img, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(item.formattedLineTotal),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.quantity <= 1 || item.id == null
                            ? null
                            : () => store.updateQuantity(item.id!, item.quantity - 1),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: item.id == null
                            ? null
                            : () => store.updateQuantity(item.id!, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: item.id == null ? null : () => store.remove(item.id!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutBar(BuildContext context, CartStore store) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                  Text(store.cart.formattedSubtotal,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: NYTheme.pink,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
