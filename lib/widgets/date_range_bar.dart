import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sales_provider.dart';
import '../utils/formatters.dart';

/// A horizontal bar showing the active date range with quick presets.
class DateRangeBar extends StatelessWidget {
  const DateRangeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text('${formatDate(provider.from)} – ${formatDate(provider.to)}'),
            onPressed: () => _pickRange(context, provider),
          ),
          const SizedBox(width: 8),
          _preset(context, provider, 'This month', _thisMonth()),
          _preset(context, provider, 'Last 3M', _lastMonths(3)),
          _preset(context, provider, 'Last 6M', _lastMonths(6)),
          _preset(context, provider, 'This year', _thisYear()),
        ],
      ),
    );
  }

  Widget _preset(
    BuildContext context,
    SalesProvider provider,
    String label,
    DateTimeRange range,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => provider.setDateRange(range.start, range.end),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, SalesProvider provider) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: provider.from, end: provider.to),
    );
    if (picked != null) {
      await provider.setDateRange(picked.start, picked.end);
    }
  }

  static DateTimeRange _thisMonth() {
    final now = DateTime.now();
    return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }

  static DateTimeRange _lastMonths(int n) {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month - (n - 1), 1),
      end: now,
    );
  }

  static DateTimeRange _thisYear() {
    final now = DateTime.now();
    return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
  }
}
