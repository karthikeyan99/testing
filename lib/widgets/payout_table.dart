import 'package:flutter/material.dart';

import '../models/payout.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

/// Monthly net-payout table: what actually reached your bank each month,
/// split into Flipkart and Amazon with a combined total.
class PayoutTable extends StatelessWidget {
  final List<PayoutMonth> payouts;
  const PayoutTable({super.key, required this.payouts});

  @override
  Widget build(BuildContext context) {
    if (payouts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Import a settlement report to see your net payouts',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final grandFlipkart = payouts.fold<double>(0, (a, b) => a + b.flipkart);
    final grandAmazon = payouts.fold<double>(0, (a, b) => a + b.amazon);
    final grandTotal = grandFlipkart + grandAmazon;

    return Column(
      children: [
        _row(
          context,
          left: 'Month',
          flipkart: 'Flipkart',
          amazon: 'Amazon',
          total: 'Total',
          isHeader: true,
        ),
        const Divider(height: 16),
        ...payouts.map(
          (p) => _row(
            context,
            left: formatMonth(p.month),
            flipkart: p.flipkart == 0 ? '–' : moneyCompact(p.flipkart),
            amazon: p.amazon == 0 ? '–' : moneyCompact(p.amazon),
            total: money(p.total),
          ),
        ),
        const Divider(height: 16),
        _row(
          context,
          left: 'All time',
          flipkart: moneyCompact(grandFlipkart),
          amazon: moneyCompact(grandAmazon),
          total: money(grandTotal),
          isTotal: true,
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required String left,
    required String flipkart,
    required String amazon,
    required String total,
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final weight =
        (isHeader || isTotal) ? FontWeight.bold : FontWeight.normal;
    final headerColor = isHeader ? Colors.black54 : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(left,
                style: TextStyle(fontWeight: weight, color: headerColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              flipkart,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: weight,
                color: isHeader ? AppColors.flipkart : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              amazon,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: weight,
                color: isHeader ? AppColors.amazon : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              total,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? AppColors.profit : headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
