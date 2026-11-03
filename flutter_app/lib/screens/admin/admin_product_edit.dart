import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../models/product.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';

/// Create or edit a product. Archive = soft deactivate (reversible); delete is a
/// hard remove.
class AdminProductEdit extends StatefulWidget {
  const AdminProductEdit({super.key, required this.service, this.product});
  final AdminService service;
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<AdminProductEdit> createState() => _AdminProductEditState();
}

class _AdminProductEditState extends State<AdminProductEdit> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _salePrice;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _tags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _salePrice = TextEditingController(text: p?.salePrice == null ? '' : p!.salePrice!.toStringAsFixed(2));
    _stock = TextEditingController(text: p == null ? '' : '${p.stockQuantity}');
    _sku = TextEditingController(text: p?.sku ?? '');
    _tags = TextEditingController(text: (p?.tags ?? const []).join(', '));
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _category, _price, _salePrice, _stock, _sku, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _tagList =>
      _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _category.text.trim().isNotEmpty &&
      double.tryParse(_price.text) != null &&
      int.tryParse(_stock.text) != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.parse(_price.text),
        'salePrice': _salePrice.text.trim().isEmpty ? null : double.tryParse(_salePrice.text),
        'category': _category.text.trim(),
        'stockQuantity': int.parse(_stock.text),
        'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        'tags': _tagList,
        if (!widget.isEditing) 'imageURLs': <String>[],
      };
      if (widget.isEditing) {
        await widget.service.updateProduct(widget.product!.id, body);
      } else {
        await widget.service.createProduct(body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setArchived(bool archived) async {
    try {
      await widget.service.setActive(widget.product!.id, !archived);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This permanently removes the product. Consider Archive instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.deleteProduct(widget.product!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e);
    }
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e is ApiException ? e.message : 'Something went wrong')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final active = p?.isActive ?? true;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Product' : 'New Product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_name, 'Name'),
          _field(_category, 'Category'),
          _field(_sku, 'SKU (optional)'),
          _field(_tags, 'Tags (comma separated)'),
          _field(_desc, 'Description', maxLines: 4),
          Row(children: [
            Expanded(child: _field(_price, 'Price', number: true)),
            const SizedBox(width: 12),
            Expanded(child: _field(_salePrice, 'Sale price', number: true)),
          ]),
          _field(_stock, 'Stock quantity', number: true),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NYTheme.pink, minimumSize: const Size.fromHeight(50)),
            onPressed: (!_valid || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.isEditing ? 'Save Changes' : 'Create Product'),
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 20),
            const Divider(),
            if (active)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Product'),
                subtitle: const Text('Hides it from the store; restorable anytime.'),
                onTap: () => _setArchived(true),
              )
            else
              ListTile(
                leading: const Icon(Icons.unarchive_outlined, color: Colors.green),
                title: const Text('Restore Product'),
                onTap: () => _setArchived(false),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Product', style: TextStyle(color: Colors.red)),
              onTap: _delete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
