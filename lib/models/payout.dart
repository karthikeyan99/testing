import 'enums.dart';
import 'sale.dart';

/// Net payout for one calendar month, split by marketplace. "Payout" is the
/// money that actually reaches your bank (settlement value), grouped by the
/// month it was settled.
class PayoutMonth {
  final DateTime month; // first day of the month
  final Map<Marketplace, double> byMarketplace;
  final int orders;

  const PayoutMonth({
    required this.month,
    required this.byMarketplace,
    required this.orders,
  });

  double get flipkart => byMarketplace[Marketplace.flipkart] ?? 0;
  double get amazon => byMarketplace[Marketplace.amazon] ?? 0;
  double get total => flipkart + amazon;

  /// Builds a per-month, per-marketplace payout breakdown from sales, sorted
  /// newest month first.
  static List<PayoutMonth> from(List<Sale> sales) {
    final months = <DateTime, Map<Marketplace, double>>{};
    final counts = <DateTime, int>{};

    for (final s in sales) {
      final d = s.payoutDate;
      final key = DateTime(d.year, d.month);
      final bucket = months.putIfAbsent(key, () => {});
      bucket.update(
        s.marketplace,
        (v) => v + s.netPayout,
        ifAbsent: () => s.netPayout,
      );
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }

    final result = months.entries
        .map((e) => PayoutMonth(
              month: e.key,
              byMarketplace: e.value,
              orders: counts[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return result;
  }
}
