import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/sale.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/formatters.dart';

/// Form to create or edit a single sale/order line.
class AddEditSaleScreen extends StatefulWidget {
  final Sale? existing;
  const AddEditSaleScreen({super.key, this.existing});

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  late Marketplace _marketplace;
  late OrderStatus _status;
  late DateTime _date;
  late bool _interState;
  late double _gstRate;

  final _orderId = TextEditingController();
  final _sku = TextEditingController();
  final _product = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _unitPrice = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _commission = TextEditingController(text: '0');
  final _shipping = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _cost = TextEditingController(text: '0');

  static const _gstRates = [0.0, 3, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _marketplace = s?.marketplace ?? Marketplace.flipkart;
    _status = s?.status ?? OrderStatus.delivered;
    _date = s?.orderDate ?? DateTime.now();
    _interState = s?.isInterState ?? false;
    _gstRate = s?.gstRate ?? 18;
    if (s != null) {
      _orderId.text = s.orderId;
      _sku.text = s.sku;
      _product.text = s.productName;
      _qty.text = s.quantity.toString();
      _unitPrice.text = s.unitPrice.toString();
      _discount.text = s.discount.toString();
      _commission.text = s.commissionFee.toString();
      _shipping.text = s.shippingFee.toString();
      _other.text = s.otherFees.toString();
      _cost.text = s.costPrice.toString();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _orderId, _sku, _product, _qty, _unitPrice, _discount,
      _commission, _shipping, _other, _cost,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  int _i(TextEditingController c) => int.tryParse(c.text.trim()) ?? 1;

  Sale _build() {
    return Sale(
      id: widget.existing?.id,
      marketplace: _marketplace,
      orderId: _orderId.text.trim(),
      orderDate: _date,
      sku: _sku.text.trim(),
      productName: _product.text.trim(),
      quantity: _i(_qty),
      unitPrice: _d(_unitPrice),
      discount: _d(_discount),
      commissionFee: _d(_commission),
      shippingFee: _d(_shipping),
      otherFees: _d(_other),
      costPrice: _d(_cost),
      gstRate: _gstRate,
      isInterState: _interState,
      status: _status,
    );
  }

  Future<void> _onSkuChanged(String sku) async {
    if (sku.trim().isEmpty) return;
    final product =
        await context.read<InventoryProvider>().findBySku(sku.trim());
    if (product != null && mounted) {
      setState(() {
        if (_product.text.isEmpty) _product.text = product.name;
        if (_d(_cost) == 0) _cost.text = product.costPrice.toString();
        _gstRate = product.gstRate;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final sale = _build();
    final provider = context.read<SalesProvider>();
    if (widget.existing == null) {
      await provider.addSale(sale);
    } else {
      await provider.updateSale(sale);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await context.read<SalesProvider>().deleteSale(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _build();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Sale' : 'Edit Sale'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: _LivePreviewBar(sale: preview),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _segMarketplace(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(_orderId, 'Order ID', required: true),
                ),
                const SizedBox(width: 12),
                Expanded(child: _datePicker()),
              ],
            ),
            const SizedBox(height: 12),
            _field(_sku, 'SKU', onChanged: _onSkuChanged),
            const SizedBox(height: 12),
            _field(_product, 'Product name'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_qty, 'Quantity',
                      keyboard: TextInputType.number, required: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_unitPrice, 'Unit price (incl. GST)',
                      keyboard: TextInputType.number, required: true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_discount, 'Discount',
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_cost, 'Cost / unit',
                      keyboard: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel('Marketplace fees'),
            Row(
              children: [
                Expanded(
                  child: _field(_commission, 'Commission',
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_shipping, 'Shipping',
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_other, 'Other',
                      keyboard: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel('Tax (GST)'),
            Row(
              children: [
                Expanded(child: _gstDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inter-state', style: TextStyle(fontSize: 13)),
                    subtitle: Text(_interState ? 'IGST' : 'CGST + SGST',
                        style: const TextStyle(fontSize: 11)),
                    value: _interState,
                    onChanged: (v) => setState(() => _interState = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statusDropdown(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endContained,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
    );
  }

  Widget _segMarketplace() {
    return SegmentedButton<Marketplace>(
      segments: const [
        ButtonSegment(value: Marketplace.flipkart, label: Text('Flipkart')),
        ButtonSegment(value: Marketplace.amazon, label: Text('Amazon')),
      ],
      selected: {_marketplace},
      onSelectionChanged: (s) => setState(() => _marketplace = s.first),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    bool required = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (v) {
        onChanged?.call(v);
        setState(() {});
      },
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2018),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Order date', isDense: true),
        child: Text(formatDate(_date)),
      ),
    );
  }

  Widget _gstDropdown() {
    return DropdownButtonFormField<double>(
      value: _gstRate,
      decoration: const InputDecoration(labelText: 'GST rate', isDense: true),
      items: [
        for (final r in _gstRates)
          DropdownMenuItem(value: r, child: Text('${r.toStringAsFixed(0)}%')),
      ],
      onChanged: (v) => setState(() => _gstRate = v ?? 18),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<OrderStatus>(
      value: _status,
      decoration: const InputDecoration(labelText: 'Status', isDense: true),
      items: [
        for (final s in OrderStatus.values)
          DropdownMenuItem(value: s, child: Text(s.label)),
      ],
      onChanged: (v) => setState(() => _status = v ?? OrderStatus.delivered),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
}

class _LivePreviewBar extends StatelessWidget {
  final Sale sale;
  const _LivePreviewBar({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _kv('Gross', money(sale.grossAmount)),
            _kv('GST', money(sale.gstAmount)),
            _kv('Profit', money(sale.netProfit)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(fontSize: 11)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}
