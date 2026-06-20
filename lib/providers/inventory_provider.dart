import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final ProductRepository _repo;

  InventoryProvider({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  List<Product> _items = [];
  bool _loading = false;

  List<Product> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  List<Product> get lowStock => _items.where((p) => p.isLowStock).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<Product?> findBySku(String sku) => _repo.findBySku(sku);

  Future<void> save(Product product) async {
    if (product.id == null) {
      await _repo.insert(product);
    } else {
      await _repo.update(product);
    }
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
