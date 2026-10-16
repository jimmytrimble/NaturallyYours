import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme.dart';

/// Full product page. (Add-to-cart lands when we port the cart/session layer.)
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cleaned = product.description
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Scaffold(
      appBar: AppBar(),
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
            onPressed: product.inStock
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cart coming soon')),
                    )
                : null,
            child: Text(product.inStock ? 'Add to Cart' : 'Sold Out'),
          ),
        ),
      ),
    );
  }
}
