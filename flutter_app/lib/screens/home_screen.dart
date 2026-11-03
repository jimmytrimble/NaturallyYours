import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import 'shop_screen.dart';

/// Landing screen: full-bleed rotating hero, featured best-sellers rail, and
/// shop-by-collection tiles. Mirrors the iOS Home.
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

  void _openShop([String? category]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(category ?? 'Shop')),
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
        padding: EdgeInsets.zero,
        children: [
          _HomeHero(onShopNow: () => _openShop()),
          // Centered, width-capped content so it looks right on wide windows too.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  if (_featured.isNotEmpty) ...[
                    const _SectionHeader('Featured Best Sellers', 'Our most-loved picks'),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) =>
                            SizedBox(width: 165, child: ProductCard(product: _featured[i])),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (categories.isNotEmpty) ...[
                    const _SectionHeader('Shop by Collection', 'Find your routine'),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          for (final c in categories)
                            _CollectionTile(
                              name: c,
                              count: _products.where((p) => p.category == c).length,
                              onTap: () => _openShop(c),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Rotating hero

class _HomeHero extends StatefulWidget {
  const _HomeHero({required this.onShopNow});
  final VoidCallback onShopNow;

  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  static const _images = [
    'assets/hero/header_photo.png',
    'assets/hero/hero_portrait_1.jpg',
    'assets/hero/hero_portrait_2.jpg',
    'assets/hero/hero_portrait_3.jpg',
  ];

  final _controller = PageController();
  int _index = 0;
  bool _zoomed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startZoom();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % _images.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 900), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startZoom() {
    setState(() => _zoomed = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _zoomed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height * 0.56).clamp(440.0, 640.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Rotating, slowly-zooming images
          PageView.builder(
            controller: _controller,
            itemCount: _images.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _startZoom();
            },
            itemBuilder: (_, i) => ClipRect(
              child: AnimatedScale(
                scale: (i == _index && _zoomed) ? 1.12 : 1.0,
                duration: const Duration(seconds: 7),
                curve: Curves.easeOut,
                child: Image.asset(_images[i], fit: BoxFit.cover),
              ),
            ),
          ),
          // Legibility gradient (darker top for status bar, dark bottom for text)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x11000000), Color(0x11000000), Color(0x99000000)],
                stops: [0, 0.35, 0.6, 1],
              ),
            ),
          ),
          // Branding + CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Naturally Yours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'BEAUTY SUPPLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Premium care, made for natural hair',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: NYTheme.pink,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: widget.onShopNow,
                  child: const Text('Shop Now',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _images.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(i == _index ? 0.95 : 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Shared bits

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(width: 44, height: 3, color: NYTheme.pink),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.name, required this.count, required this.onTap});
  final String name;
  final int count;
  final VoidCallback onTap;

  IconData get _icon => switch (name) {
        'Bundles' => Icons.inventory_2_outlined,
        'Skincare' => Icons.spa_outlined,
        'Haircare' => Icons.content_cut,
        'Treatments' => Icons.water_drop_outlined,
        'Men' => Icons.person_outline,
        _ => Icons.grid_view,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NYTheme.pink.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NYTheme.pink.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 34, color: NYTheme.pink),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$count ${count == 1 ? "Product" : "Products"}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
