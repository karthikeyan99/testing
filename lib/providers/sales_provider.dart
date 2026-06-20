import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/sale.dart';
import '../models/sales_summary.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

/// Central store for sales data plus the active date/marketplace/status filter.
class SalesProvider extends ChangeNotifier {
  final SaleRepository _sales;
  final ProductRepository _products;

  SalesProvider({
    SaleRepository? saleRepository,
    ProductRepository? productRepository,
  })  : _sales = saleRepository ?? SaleRepository(),
        _products = productRepository ?? ProductRepository();

  List<Sale> _items = [];
  bool _loading = false;
  String? _error;

  // Active filters.
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month - 5, 1);
  DateTime _to = DateTime.now();
  Marketplace? _marketplace;
  OrderStatus? _status;
  String _search = '';

  List<Sale> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  DateTime get from => _from;
  DateTime get to => _to;
  Marketplace? get marketplace => _marketplace;
  OrderStatus? get status => _status;
  String get search => _search;

  SalesSummary get summary => SalesSummary.from(_items);

  SaleFilter get _filter => SaleFilter(
        from: DateTime(_from.year, _from.month, _from.day),
        to: DateTime(_to.year, _to.month, _to.day, 23, 59, 59),
        marketplace: _marketplace?.name,
        status: _status?.name,
        search: _search.isEmpty ? null : _search,
      );

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _sales.getAll(_filter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) async {
    _from = from;
    _to = to;
    await load();
  }

  Future<void> setMarketplace(Marketplace? m) async {
    _marketplace = m;
    await load();
  }

  Future<void> setStatus(OrderStatus? s) async {
    _status = s;
    await load();
  }

  Future<void> setSearch(String q) async {
    _search = q;
    await load();
  }

  Future<void> addSale(Sale sale, {bool reduceStock = true}) async {
    await _sales.insert(sale);
    if (reduceStock && sale.status.countsAsSale && sale.sku.isNotEmpty) {
      await _products.decrementStock(sale.sku, sale.quantity);
    }
    await load();
  }

  Future<void> updateSale(Sale sale) async {
    await _sales.update(sale);
    await load();
  }

  Future<void> deleteSale(int id) async {
    await _sales.delete(id);
    await load();
  }

  /// Bulk import (from CSV). Returns rows written.
  Future<int> importSales(List<Sale> sales) async {
    final n = await _sales.insertAll(sales);
    await load();
    return n;
  }
}
