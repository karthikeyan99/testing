import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../services/csv_export_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/date_range_bar.dart';

/// Tax (GST) and profit & loss reporting for the active date range.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final sales = provider.items;
    final s = provider.summary;
    final gstRows = _gstByRate(sales);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export GST summary',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: sales.isEmpty
                ? null
                : () => _exportGst(context, sales),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const DateRangeBar(),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Profit & Loss',
            child: Column(
              children: [
                _row('Gross revenue', money(s.grossRevenue)),
                _row('Less: GST collected', '- ${money(s.gstCollected)}'),
                _row('Taxable revenue', money(s.taxableRevenue), bold: true),
                _row('Less: product cost', '- ${money(s.totalCost)}'),
                _row('Less: marketplace fees', '- ${money(s.totalFees)}'),
                const Divider(),
                _row(
                  'Net profit',
                  money(s.netProfit),
                  bold: true,
                  color: s.netProfit >= 0 ? AppColors.profit : AppColors.loss,
                ),
                _row('Profit margin', '${s.profitMargin.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          _card(
            context,
            title: 'GST Summary (by rate)',
            child: gstRows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No taxable sales in this period',
                        style: TextStyle(color: Colors.black54)),
                  )
                : Column(
                    children: [
                      _gstHeader(),
                      const Divider(),
                      for (final r in gstRows) _gstRow(r),
                      const Divider(),
                      _gstTotalRow(gstRows),
                    ],
                  ),
          ),
          _card(
            context,
            title: 'Orders',
            child: Column(
              children: [
                _row('Orders counted', '${s.orderCount}'),
                _row('Units sold', '${s.unitsSold}'),
                _row('Returned / cancelled', '${s.returnedCount}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: OutlinedButton.icon(
              onPressed: sales.isEmpty ? null : () => _exportSales(context, sales),
              icon: const Icon(Icons.ios_share),
              label: const Text('Export full sales CSV'),
            ),
          ),
        ],
      ),
    );
  }

  List<_GstRow> _gstByRate(List<Sale> sales) {
    final map = <double, _GstRow>{};
    for (final s in sales) {
      if (!s.status.countsAsSale) continue;
      final row = map.putIfAbsent(s.gstRate, () => _GstRow(s.gstRate));
      row.taxable += s.taxableValue;
      row.cgst += s.cgst;
      row.sgst += s.sgst;
      row.igst += s.igst;
    }
    final list = map.values.toList()..sort((a, b) => a.rate.compareTo(b.rate));
    return list;
  }

  Widget _card(BuildContext context,
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  Widget _gstHeader() {
    return const Row(
      children: [
        Expanded(flex: 2, child: Text('Rate', style: _th)),
        Expanded(flex: 3, child: Text('Taxable', style: _th, textAlign: TextAlign.right)),
        Expanded(flex: 3, child: Text('CGST', style: _th, textAlign: TextAlign.right)),
        Expanded(flex: 3, child: Text('SGST', style: _th, textAlign: TextAlign.right)),
        Expanded(flex: 3, child: Text('IGST', style: _th, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _gstRow(_GstRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('${r.rate.toStringAsFixed(0)}%')),
          Expanded(flex: 3, child: Text(money(r.taxable), textAlign: TextAlign.right, style: _td)),
          Expanded(flex: 3, child: Text(money(r.cgst), textAlign: TextAlign.right, style: _td)),
          Expanded(flex: 3, child: Text(money(r.sgst), textAlign: TextAlign.right, style: _td)),
          Expanded(flex: 3, child: Text(money(r.igst), textAlign: TextAlign.right, style: _td)),
        ],
      ),
    );
  }

  Widget _gstTotalRow(List<_GstRow> rows) {
    final taxable = rows.fold<double>(0, (a, b) => a + b.taxable);
    final cgst = rows.fold<double>(0, (a, b) => a + b.cgst);
    final sgst = rows.fold<double>(0, (a, b) => a + b.sgst);
    final igst = rows.fold<double>(0, (a, b) => a + b.igst);
    const bold = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('Total', style: bold)),
          Expanded(flex: 3, child: Text(money(taxable), textAlign: TextAlign.right, style: bold)),
          Expanded(flex: 3, child: Text(money(cgst), textAlign: TextAlign.right, style: bold)),
          Expanded(flex: 3, child: Text(money(sgst), textAlign: TextAlign.right, style: bold)),
          Expanded(flex: 3, child: Text(money(igst), textAlign: TextAlign.right, style: bold)),
        ],
      ),
    );
  }

  Future<void> _exportGst(BuildContext context, List<Sale> sales) async {
    try {
      await CsvExportService().exportGstSummary(sales);
    } catch (e) {
      _err(context, e);
    }
  }

  Future<void> _exportSales(BuildContext context, List<Sale> sales) async {
    try {
      await CsvExportService().exportSales(sales);
    } catch (e) {
      _err(context, e);
    }
  }

  void _err(BuildContext context, Object e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

const _th = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54);
const _td = TextStyle(fontSize: 12);

class _GstRow {
  final double rate;
  double taxable = 0;
  double cgst = 0;
  double sgst = 0;
  double igst = 0;
  _GstRow(this.rate);
}
