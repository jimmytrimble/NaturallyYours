import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../models/admin_models.dart';
import '../../models/product.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';
import 'admin_product_edit.dart';

/// Admin inventory: list all products (active + inactive), toggle featured,
/// archive/restore, and open the editor. Includes a quick stats strip.
class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key, required this.service, required this.admin});
  final AdminService service;
  final AdminUser admin;

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  List<Product> _all = [];
  AdminStats? _stats;
  bool _loading = true;
  String _query = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await widget.service.loadAllProducts();
      _stats = await widget.service.stats();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Product> get _visible {
    final base = _all.where((p) => p.isActive == !_showInactive);
    if (_query.trim().isEmpty) return base.toList();
    final q = _query.toLowerCase();
    return base.where((p) =>
        p.name.toLowerCase().contains(q) || (p.sku?.toLowerCase().contains(q) ?? false)).toList();
  }

  int get _inactiveCount => _all.where((p) => !p.isActive).length;

  Future<void> _openEditor([Product? product]) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AdminProductEdit(service: widget.service, product: product),
    ));
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: widget.admin.canManageCatalog
          ? FloatingActionButton(
              backgroundColor: NYTheme.pink,
              onPressed: () => _openEditor(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_stats != null) _statsStrip(_stats!),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or SKU',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Active'),
                  selected: !_showInactive,
                  onSelected: (_) => setState(() => _showInactive = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Inactive ($_inactiveCount)'),
                  selected: _showInactive,
                  onSelected: (_) => setState(() => _showInactive = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in _visible) _row(p),
            if (_visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No products', style: TextStyle(color: Colors.grey))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsStrip(AdminStats s) {
    Widget pill(String label, int value) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        );
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          pill('Products', s.totalProducts),
          pill('Active', s.activeProducts),
          pill('Orders', s.orders),
          pill('Messages', s.openConversations),
          pill('Customers', s.users),
        ],
      ),
    );
  }

  Widget _row(Product p) {
    final img = p.primaryImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48, height: 48,
            child: img == null
                ? Container(color: const Color(0xFFF0F0F0), child: const Icon(Icons.photo, color: Colors.black26))
                : Image.network(img, fit: BoxFit.cover),
          ),
        ),
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${p.formattedPrice} · Stock ${p.stockQuantity}',
            style: TextStyle(color: p.inStock ? Colors.grey : Colors.red)),
        trailing: widget.admin.canManageCatalog
            ? IconButton(
                tooltip: p.isFeatured ? 'Unfeature' : 'Feature',
                icon: Icon(p.isFeatured ? Icons.star : Icons.star_border,
                    color: p.isFeatured ? NYTheme.pink : Colors.grey),
                onPressed: () => _toggleFeatured(p),
              )
            : null,
        onTap: () => _openEditor(p),
      ),
    );
  }

  Future<void> _toggleFeatured(Product p) async {
    try {
      await widget.service.setFeatured(p.id, !p.isFeatured);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not update')),
        );
      }
    }
  }
}
