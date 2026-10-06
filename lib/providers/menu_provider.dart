import 'package:flutter/foundation.dart';
import '../data/menu_repository.dart';
import '../models/menu_item.dart';

class MenuProvider extends ChangeNotifier {
  final MenuRepository _repository;
  List<MenuItem> _items = [];
  bool _isLoading = false;

  MenuProvider({MenuRepository? repository})
      : _repository = repository ?? SqliteMenuRepository() {
    loadMenuItems();
  }

  List<MenuItem> get items => _items.isEmpty ? defaultMenuItems : _items;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final activeItems = items;
    final set = activeItems
        .map((e) => e.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  Future<void> loadMenuItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _repository.getMenuItems();
      _items = fetched.isNotEmpty ? fetched : List.from(defaultMenuItems);
    } catch (e) {
      debugPrint('Error loading menu items: $e');
      if (_items.isEmpty) {
        _items = List.from(defaultMenuItems);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MenuItem> addMenuItem({
    required String name,
    required int price,
    required String category,
  }) async {
    final trimmedName = name.trim();
    final trimmedCategory =
        category.trim().isEmpty ? 'General' : category.trim();
    final item = MenuItem(
      id: 0,
      name: trimmedName,
      price: price,
      category: trimmedCategory,
    );
    final id = await _repository.addMenuItem(item);
    final created = item.copyWith(id: id);
    await loadMenuItems();
    return created;
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _repository.updateMenuItem(item);
    await loadMenuItems();
  }

  Future<void> updateRate({required int id, required int newPrice}) async {
    final existing = items.firstWhere(
      (e) => e.id == id,
      orElse: () =>
          defaultMenuItems.firstWhere((e) => e.id == id),
    );
    final updated = existing.copyWith(price: newPrice);
    await _repository.updateMenuItem(updated);
    await loadMenuItems();
  }

  Future<void> deleteMenuItem(int id) async {
    await _repository.deleteMenuItem(id);
    await loadMenuItems();
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await loadMenuItems();
  }

  MenuItem? findById(int id) {
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
