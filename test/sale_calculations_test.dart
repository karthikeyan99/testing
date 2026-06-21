import 'package:flutter_test/flutter_test.dart';
import 'package:sales_tracker/models/enums.dart';
import 'package:sales_tracker/models/payout.dart';
import 'package:sales_tracker/models/sale.dart';
import 'package:sales_tracker/models/sales_summary.dart';

void main() {
  Sale build({
    double unitPrice = 1180,
    int qty = 1,
    double gstRate = 18,
    bool interState = false,
    double cost = 600,
    double commission = 100,
    OrderStatus status = OrderStatus.delivered,
  }) {
    return Sale(
      marketplace: Marketplace.amazon,
      orderId: 'O1',
      orderDate: DateTime(2026, 1, 15),
      sku: 'SKU1',
      productName: 'Widget',
      quantity: qty,
      unitPrice: unitPrice,
      gstRate: gstRate,
      isInterState: interState,
      costPrice: cost,
      commissionFee: commission,
      status: status,
    );
  }

  group('GST back-calculation', () {
    test('extracts 18% GST from an inclusive price', () {
      final s = build(unitPrice: 1180, gstRate: 18);
      expect(s.grossAmount, 1180);
      expect(s.taxableValue, closeTo(1000, 0.01));
      expect(s.gstAmount, closeTo(180, 0.01));
    });

    test('splits into CGST + SGST for intra-state', () {
      final s = build(unitPrice: 1180, gstRate: 18, interState: false);
      expect(s.cgst, closeTo(90, 0.01));
      expect(s.sgst, closeTo(90, 0.01));
      expect(s.igst, 0);
    });

    test('uses IGST for inter-state', () {
      final s = build(unitPrice: 1180, gstRate: 18, interState: true);
      expect(s.igst, closeTo(180, 0.01));
      expect(s.cgst, 0);
      expect(s.sgst, 0);
    });
  });

  group('Profit', () {
    test('net profit = taxable - cost - fees', () {
      final s = build(unitPrice: 1180, cost: 600, commission: 100);
      // taxable 1000 - cost 600 - fees 100 = 300
      expect(s.netProfit, closeTo(300, 0.01));
    });
  });

  group('SalesSummary', () {
    test('excludes returned orders from totals but counts them', () {
      final summary = SalesSummary.from([
        build(status: OrderStatus.delivered),
        build(status: OrderStatus.returned),
      ]);
      expect(summary.orderCount, 1);
      expect(summary.returnedCount, 1);
      expect(summary.grossRevenue, closeTo(1180, 0.01));
    });

    test('aggregates multiple quantities', () {
      final summary = SalesSummary.from([build(qty: 3)]);
      expect(summary.unitsSold, 3);
      expect(summary.grossRevenue, closeTo(3540, 0.01));
    });
  });

  group('Payout (settlement)', () {
    Sale settled(Marketplace m, double value, DateTime when) => Sale(
          marketplace: m,
          orderId: 'O',
          orderDate: when,
          sku: 'S',
          productName: 'P',
          quantity: 1,
          unitPrice: 0,
          settlementValue: value,
          settlementDate: when,
        );

    test('net payout prefers the real settlement value', () {
      final s = settled(Marketplace.flipkart, 117.41, DateTime(2026, 6, 19));
      expect(s.netPayout, closeTo(117.41, 0.001));
      expect(s.payoutDate, DateTime(2026, 6, 19));
    });

    test('groups by settlement month and splits by marketplace', () {
      final months = PayoutMonth.from([
        settled(Marketplace.flipkart, 100, DateTime(2026, 6, 5)),
        settled(Marketplace.flipkart, 50, DateTime(2026, 6, 20)),
        settled(Marketplace.amazon, 70, DateTime(2026, 6, 10)),
        settled(Marketplace.flipkart, 30, DateTime(2026, 5, 2)),
        // A return reduces the month total via its negative settlement.
        settled(Marketplace.flipkart, -20, DateTime(2026, 6, 25)),
      ]);

      final june = months.firstWhere((m) => m.month == DateTime(2026, 6));
      expect(june.flipkart, closeTo(130, 0.01)); // 100 + 50 - 20
      expect(june.amazon, closeTo(70, 0.01));
      expect(june.total, closeTo(200, 0.01));

      // Sorted newest-first.
      expect(months.first.month, DateTime(2026, 6));
      expect(months.last.month, DateTime(2026, 5));
    });
  });
}
