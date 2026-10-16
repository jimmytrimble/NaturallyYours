import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import 'shop_screen.dart';

/// Landing screen: brand header, featured best-sellers rail, and shop-by-collection.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = CatalogService();
  List<Product> _products = [];
  List<Product> _featured = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _service.loadProducts();
      List<Product> featured = [];
      try {
        featured = await _service.loadFeatured();
      } catch (_) {}
      if (featured.isEmpty) {
        featured = products.where((p) => p.onSale && p.inStock).take(8).toList();
        if (featured.isEmpty) featured = products.take(8).toList();
      }
      if (!mounted) return;
      setState(() {
        _products = products;
        _featured = featured;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openCategory(String category) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(category)),
        body: ShopScreen(initialCategory: category),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final categories = _service.categories(_products);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Text('Naturally Yours',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic)),
                SizedBox(height: 2),
                Text('BEAUTY SUPPLY',
                    style: TextStyle(
                        fontSize: 12, letterSpacing: 5, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_featured.isNotEmpty) ...[
            _sectionHeader('Featured Best Sellers', 'Our most-loved picks'),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    SizedBox(width: 170, child: ProductCard(product: _featured[i])),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (categories.isNotEmpty) ...[
            _sectionHeader('Shop by Collection', 'Find your routine'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  for (final c in categories)
                    _CollectionTile(
                      name: c,
                      count: _products.where((p) => p.category == c).length,
                      onTap: () => _openCategory(c),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(width: 44, height: 3, color: NYTheme.pink),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile(
      {required this.name, required this.count, required this.onTap});
  final String name;
  final int count;
  final VoidCallback onTap;

  IconData get _icon {
    switch (name) {
      case 'Bundles':
        return Icons.inventory_2_outlined;
      case 'Skincare':
        return Icons.spa_outlined;
      case 'Haircare':
        return Icons.content_cut;
      case 'Treatments':
        return Icons.water_drop_outlined;
      case 'Men':
        return Icons.person_outline;
      default:
        return Icons.grid_view;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NYTheme.pink.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 36, color: NYTheme.pink),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$count ${count == 1 ? "Product" : "Products"}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
