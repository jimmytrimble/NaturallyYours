import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import 'product_detail_screen.dart';

/// Browse the catalog with category chips and a product grid.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialCategory});

  /// Preselect a category (used when navigating from a Home collection tile).
  final String? initialCategory;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _service = CatalogService();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _service.loadProducts();
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Product> get _visible => _selectedCategory == null
      ? _products
      : _products.where((p) => p.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final categories = _service.categories(_products);

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Shop', style: NYTheme.screenTitle),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('All', _selectedCategory == null,
                      () => setState(() => _selectedCategory = null)),
                  for (final c in categories)
                    _chip(c, _selectedCategory == c,
                        () => setState(() => _selectedCategory = c)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ProductCard(product: _visible[i]),
                childCount: _visible.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: NYTheme.pink,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// A product grid card (shared look with the iOS app).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _image(product.primaryImageUrl),
                  ),
                ),
                if (product.onSale)
                  const Positioned(top: 8, left: 8, child: _Badge('SALE')),
                if (!product.inStock)
                  const Positioned(
                      top: 8, left: 8, child: _Badge('SOLD OUT', muted: true)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1),
          ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                product.formattedPrice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: product.onSale ? NYTheme.pink : null,
                ),
              ),
              if (product.onSale) ...[
                const SizedBox(width: 6),
                Text(
                  product.formattedOriginalPrice,
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget _image(String? url) {
  if (url == null) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Icon(Icons.photo, color: Colors.black26, size: 40),
    );
  }
  return Image.network(
    url,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
      color: const Color(0xFFF2F2F2),
      child: const Icon(Icons.photo, color: Colors.black26, size: 40),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted ? Colors.black54 : NYTheme.pink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text("Couldn't load products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
