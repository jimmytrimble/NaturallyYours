import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../theme.dart';

/// Full product page with add-to-cart.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await context.read<CartStore>().add(widget.product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not add to cart')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cleaned = product.description
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .trim();

    final auth = context.watch<AuthService>();
    final favorites = context.watch<FavoritesStore>();
    final isFav = favorites.isFavorite(product);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: NYTheme.pink),
            onPressed: () async {
              if (!auth.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to save favorites')),
                );
                return;
              }
              try {
                await context.read<FavoritesStore>().toggle(product);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : 'Could not update favorite')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: const Color(0xFFF2F2F2),
              child: product.primaryImageUrl == null
                  ? const Icon(Icons.photo, size: 64, color: Colors.black26)
                  : Image.network(product.primaryImageUrl!, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.category.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(product.formattedPrice,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: product.onSale ? NYTheme.pink : null)),
                    if (product.onSale) ...[
                      const SizedBox(width: 10),
                      Text(product.formattedOriginalPrice,
                          style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(product.inStock ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: product.inStock ? Colors.green : Colors.red),
                    const SizedBox(width: 6),
                    Text(product.inStock ? 'In stock' : 'Sold out',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(cleaned, style: const TextStyle(color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: product.inStock ? NYTheme.pink : Colors.grey,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: (!product.inStock || _adding) ? null : _addToCart,
            child: _adding
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(product.inStock ? 'Add to Cart' : 'Sold Out'),
          ),
        ),
      ),
    );
  }
}
