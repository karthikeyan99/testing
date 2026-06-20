import 'enums.dart';
import 'sale.dart';

/// Aggregated figures derived from a list of sales, used by the dashboard and
/// reports. Returned/cancelled/refunded orders are excluded from realised
/// totals but counted separately.
class SalesSummary {
  final double grossRevenue;
  final double taxableRevenue;
  final double gstCollected;
  final double totalFees;
  final double totalCost;
  final double netProfit;
  final int unitsSold;
  final int orderCount;
  final int returnedCount;
  final Map<Marketplace, double> revenueByMarketplace;
  final Map<DateTime, double> revenueByMonth; // month-start -> gross revenue

  const SalesSummary({
    required this.grossRevenue,
    required this.taxableRevenue,
    required this.gstCollected,
    required this.totalFees,
    required this.totalCost,
    required this.netProfit,
    required this.unitsSold,
    required this.orderCount,
    required this.returnedCount,
    required this.revenueByMarketplace,
    required this.revenueByMonth,
  });

  double get profitMargin =>
      taxableRevenue == 0 ? 0 : (netProfit / taxableRevenue) * 100;

  factory SalesSummary.from(List<Sale> sales) {
    double gross = 0,
        taxable = 0,
        gst = 0,
        fees = 0,
        cost = 0,
        profit = 0;
    int units = 0, orders = 0, returned = 0;
    final byMarket = <Marketplace, double>{};
    final byMonth = <DateTime, double>{};

    for (final s in sales) {
      if (!s.status.countsAsSale) {
        returned++;
        continue;
      }
      gross += s.grossAmount;
      taxable += s.taxableValue;
      gst += s.gstAmount;
      fees += s.totalFees;
      cost += s.totalCost;
      profit += s.netProfit;
      units += s.quantity;
      orders++;

      byMarket.update(
        s.marketplace,
        (v) => v + s.grossAmount,
        ifAbsent: () => s.grossAmount,
      );
      final m = DateTime(s.orderDate.year, s.orderDate.month);
      byMonth.update(m, (v) => v + s.grossAmount, ifAbsent: () => s.grossAmount);
    }

    return SalesSummary(
      grossRevenue: gross,
      taxableRevenue: taxable,
      gstCollected: gst,
      totalFees: fees,
      totalCost: cost,
      netProfit: profit,
      unitsSold: units,
      orderCount: orders,
      returnedCount: returned,
      revenueByMarketplace: byMarket,
      revenueByMonth: byMonth,
    );
  }
}
