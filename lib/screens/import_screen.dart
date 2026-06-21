import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/sales_provider.dart';
import '../services/csv_import_service.dart';

/// Lets the user pick a Flipkart or Amazon report CSV, preview the parsed rows,
/// and import them.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Marketplace _marketplace = Marketplace.flipkart;
  ImportResult? _result;
  String? _fileName;
  bool _busy = false;

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      // withData: true loads bytes on every platform (incl. web, where file
      // paths aren't available), so a single code path covers all targets.
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (picked == null) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack('Could not read file contents');
        return;
      }
      final content = utf8.decode(bytes, allowMalformed: true);
      final result = CsvImportService().importString(content, _marketplace);
      setState(() {
        _result = result;
        _fileName = file.name;
      });
    } catch (e) {
      _snack('Could not read file: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmImport() async {
    final result = _result;
    if (result == null || result.sales.isEmpty) return;
    setState(() => _busy = true);
    final n = await context.read<SalesProvider>().importSales(result.sales);
    setState(() => _busy = false);
    _snack('Imported $n orders');
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Choose marketplace',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<Marketplace>(
            segments: const [
              ButtonSegment(
                  value: Marketplace.flipkart, label: Text('Flipkart')),
              ButtonSegment(value: Marketplace.amazon, label: Text('Amazon')),
            ],
            selected: {_marketplace},
            onSelectionChanged: (s) => setState(() {
              _marketplace = s.first;
              _result = null;
            }),
          ),
          const SizedBox(height: 20),
          const Text('2. Pick the report file',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _marketplace == Marketplace.flipkart
                ? 'Flipkart Seller Hub → Reports → Orders (download CSV)'
                : 'Amazon Seller Central → Reports → Order/Transaction report (CSV)',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_fileName ?? 'Select CSV file'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            const Text('3. Preview',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${result.sales.length} orders parsed',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (result.skipped > 0)
                      Text('${result.skipped} empty rows skipped',
                          style: const TextStyle(color: Colors.black54)),
                    for (final w in result.warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 16, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(w,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFE65100)))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...result.sales.take(5).map((s) => ListTile(
                  dense: true,
                  title: Text(
                      s.productName.isEmpty ? s.sku : s.productName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('#${s.orderId} · Qty ${s.quantity}'),
                  trailing: Text('₹${s.grossAmount.toStringAsFixed(0)}'),
                )),
            if (result.sales.length > 5)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('…and ${result.sales.length - 5} more',
                    style: const TextStyle(color: Colors.black54)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_busy || result.sales.isEmpty) ? null : _confirmImport,
              icon: const Icon(Icons.download_done),
              label: Text('Import ${result.sales.length} orders'),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFFE3F2FD),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Re-importing the same report is safe — orders are '
                      'de-duplicated by order ID + SKU. Live API auto-sync '
                      'can be added later without changing this flow.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
