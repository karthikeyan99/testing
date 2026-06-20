import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/sales_summary.dart';
import '../utils/formatters.dart';
import 'platform_chip.dart';

/// Monthly gross revenue as a bar chart.
class RevenueTrendChart extends StatelessWidget {
  final SalesSummary summary;
  const RevenueTrendChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries = summary.revenueByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const _EmptyChart(message: 'No revenue in this period');
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, _) => Text(
                  moneyCompact(value),
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatMonth(entries[i].key),
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value,
                    width: 16,
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Marketplace revenue split as a donut chart with a legend.
class MarketplacePieChart extends StatelessWidget {
  final SalesSummary summary;
  const MarketplacePieChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final data = summary.revenueByMarketplace;
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No sales to split');
    }
    final total = data.values.fold<double>(0, (a, b) => a + b);

    return Row(
      children: [
        SizedBox(
          height: 140,
          width: 140,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              sections: [
                for (final entry in data.entries)
                  PieChartSectionData(
                    value: entry.value,
                    color: marketplaceColor(entry.key),
                    title: total == 0
                        ? ''
                        : '${(entry.value / total * 100).round()}%',
                    radius: 30,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in data.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: marketplaceColor(entry.key),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key.label)),
                      Text(
                        money(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.black45),
        ),
      ),
    );
  }
}
