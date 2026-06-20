import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sales_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/date_range_bar.dart';
import '../widgets/sales_charts.dart';
import '../widgets/summary_card.dart';
import 'add_edit_sale_screen.dart';
import 'import_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final s = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Tracker'),
        actions: [
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditSaleScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const DateRangeBar(),
            const SizedBox(height: 12),
            if (provider.loading)
              const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  SummaryCard(
                    label: 'Gross Revenue',
                    value: money(s.grossRevenue),
                    icon: Icons.payments,
                    color: AppColors.flipkart,
                    subtitle: '${s.orderCount} orders',
                  ),
                  SummaryCard(
                    label: 'Net Profit',
                    value: money(s.netProfit),
                    icon: Icons.trending_up,
                    color: s.netProfit >= 0 ? AppColors.profit : AppColors.loss,
                    subtitle: '${s.profitMargin.toStringAsFixed(1)}% margin',
                  ),
                  SummaryCard(
                    label: 'GST Collected',
                    value: money(s.gstCollected),
                    icon: Icons.account_balance,
                    color: AppColors.tax,
                    subtitle: 'on ${money(s.taxableRevenue)} taxable',
                  ),
                  SummaryCard(
                    label: 'Marketplace Fees',
                    value: money(s.totalFees),
                    icon: Icons.remove_circle_outline,
                    color: AppColors.amazon,
                    subtitle: '${s.unitsSold} units sold',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              context,
              title: 'Revenue Trend',
              child: RevenueTrendChart(summary: s),
            ),
            _sectionCard(
              context,
              title: 'Marketplace Split',
              child: MarketplacePieChart(summary: s),
            ),
            if (s.returnedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  color: AppColors.loss.withOpacity(0.06),
                  child: ListTile(
                    leading: const Icon(Icons.assignment_return,
                        color: AppColors.loss),
                    title: Text('${s.returnedCount} returned / cancelled'),
                    subtitle: const Text('Excluded from revenue and profit'),
                  ),
                ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
