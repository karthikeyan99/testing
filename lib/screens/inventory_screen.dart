import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../utils/formatters.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: provider.lowStock.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF3E0),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    '${provider.lowStock.length} item(s) low on stock',
                    style: const TextStyle(color: Color(0xFFE65100), fontSize: 13),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? const Center(
                  child: Text('No products yet',
                      style: TextStyle(color: Colors.black54)),
                )
              : ListView.separated(
                  itemCount: provider.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = provider.items[i];
                    return ListTile(
                      onTap: () => _edit(context, p),
                      leading: CircleAvatar(
                        backgroundColor: p.isLowStock
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFC8E6C9),
                        child: Text('${p.stock}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      title: Text(p.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          'SKU ${p.sku} · Cost ${money(p.costPrice)} · GST ${p.gstRate.toStringAsFixed(0)}%'),
                      trailing: p.isLowStock
                          ? const Icon(Icons.warning_amber,
                              color: Color(0xFFE65100))
                          : null,
                    );
                  },
                ),
    );
  }

  void _edit(BuildContext context, Product? product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ProductForm(existing: product)),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? existing;
  const _ProductForm({this.existing});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '5');
  final _hsn = TextEditingController();
  double _gstRate = 18;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _sku.text = p.sku;
      _name.text = p.name;
      _cost.text = p.costPrice.toString();
      _stock.text = p.stock.toString();
      _threshold.text = p.lowStockThreshold.toString();
      _hsn.text = p.hsnCode ?? '';
      _gstRate = p.gstRate;
    }
  }

  @override
  void dispose() {
    for (final c in [_sku, _name, _cost, _stock, _threshold, _hsn]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final product = Product(
      id: widget.existing?.id,
      sku: _sku.text.trim(),
      name: _name.text.trim(),
      costPrice: double.tryParse(_cost.text.trim()) ?? 0,
      gstRate: _gstRate,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      lowStockThreshold: int.tryParse(_threshold.text.trim()) ?? 5,
      hsnCode: _hsn.text.trim().isEmpty ? null : _hsn.text.trim(),
    );
    await context.read<InventoryProvider>().save(product);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await context.read<InventoryProvider>().delete(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _sku,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost / unit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: _gstRate,
                    decoration: const InputDecoration(labelText: 'GST %'),
                    items: const <double>[0, 3, 5, 12, 18, 28]
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('${r.toStringAsFixed(0)}%')))
                        .toList(),
                    onChanged: (v) => setState(() => _gstRate = v ?? 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock on hand'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _threshold,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Low-stock alert at'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hsn,
              decoration: const InputDecoration(
                  labelText: 'HSN code (optional)',
                  helperText: 'Used for GST reporting'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}
