import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../services/csv_export_service.dart';
import '../utils/formatters.dart';
import '../widgets/platform_chip.dart';
import 'add_edit_sale_screen.dart';

class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: provider.items.isEmpty
                ? null
                : () => _export(context, provider.items),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search order / SKU / product',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: provider.setSearch,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _marketFilter(context, provider),
                    const SizedBox(width: 8),
                    _statusFilter(context, provider),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  itemCount: provider.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _SaleTile(sale: provider.items[i]),
                ),
    );
  }

  Widget _marketFilter(BuildContext context, SalesProvider provider) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: provider.marketplace == null,
          onSelected: (_) => provider.setMarketplace(null),
        ),
        const SizedBox(width: 8),
        for (final m in Marketplace.values) ...[
          ChoiceChip(
            label: Text(m.label),
            selected: provider.marketplace == m,
            onSelected: (_) => provider.setMarketplace(m),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _statusFilter(BuildContext context, SalesProvider provider) {
    return PopupMenuButton<OrderStatus?>(
      onSelected: provider.setStatus,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All statuses')),
        for (final s in OrderStatus.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 16),
        label: Text(provider.status?.label ?? 'Status'),
      ),
    );
  }

  Future<void> _export(BuildContext context, List<Sale> sales) async {
    try {
      await CsvExportService().exportSales(sales);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final profitColor =
        sale.netProfit >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditSaleScreen(existing: sale)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              sale.productName.isEmpty ? sale.sku : sale.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          PlatformChip(marketplace: sale.marketplace, dense: true),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text('#${sale.orderId} · ${formatDate(sale.orderDate)} · '
              'Qty ${sale.quantity}'),
          Row(
            children: [
              _statusBadge(sale.status),
              const SizedBox(width: 8),
              Text('Profit ', style: TextStyle(color: Colors.grey[600])),
              Text(
                money(sale.netProfit),
                style: TextStyle(color: profitColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money(sale.grossAmount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('GST ${money(sale.gstAmount)}',
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    final color = status.countsAsSale ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 56, color: Colors.black26),
          SizedBox(height: 12),
          Text('No orders for this filter',
              style: TextStyle(color: Colors.black54)),
          Text('Add a sale or import a CSV to get started',
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}
