import 'package:sqflite/sqflite.dart';
import '../models/menu_item.dart';
import 'database_helper.dart';

abstract class MenuRepository {
  Future<List<MenuItem>> getMenuItems();
  Future<int> addMenuItem(MenuItem item);
  Future<void> updateMenuItem(MenuItem item);
  Future<void> deleteMenuItem(int id);
  Future<void> resetToDefaults();
}

class SqliteMenuRepository implements MenuRepository {
  final DatabaseHelper _dbHelper;

  SqliteMenuRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<MenuItem>> getMenuItems() async {
    final db = await _dbHelper.database;
    await _ensureTableAndSeed(db);

    final result = await db.query(
      'menu_items',
      orderBy: 'id ASC',
    );
    return result.map((map) => MenuItem.fromMap(map)).toList();
  }

  Future<void> _ensureTableAndSeed(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM menu_items');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count == 0) {
      await _seedDefaults(db);
    }
  }

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();
    for (final item in defaultMenuItems) {
      batch.insert(
        'menu_items',
        {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'category': item.category,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<int> addMenuItem(MenuItem item) async {
    final db = await _dbHelper.database;
    await _ensureTableAndSeed(db);
    final map = {
      'name': item.name,
      'price': item.price,
      'category': item.category,
    };
    if (item.id > 0) {
      map['id'] = item.id;
    }
    return await db.insert(
      'menu_items',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    final db = await _dbHelper.database;
    await _ensureTableAndSeed(db);
    await db.update(
      'menu_items',
      {
        'name': item.name,
        'price': item.price,
        'category': item.category,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> deleteMenuItem(int id) async {
    final db = await _dbHelper.database;
    await _ensureTableAndSeed(db);
    await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> resetToDefaults() async {
    final db = await _dbHelper.database;
    await _ensureTableAndSeed(db);
    await db.delete('menu_items');
    await _seedDefaults(db);
  }
}

class InMemoryMenuRepository implements MenuRepository {
  final List<MenuItem> _items = [];

  InMemoryMenuRepository([List<MenuItem>? initialItems]) {
    if (initialItems != null && initialItems.isNotEmpty) {
      _items.addAll(initialItems);
    } else {
      _items.addAll(defaultMenuItems);
    }
  }

  @override
  Future<List<MenuItem>> getMenuItems() async => List.unmodifiable(_items);

  @override
  Future<int> addMenuItem(MenuItem item) async {
    final newId = item.id > 0
        ? item.id
        : (_items.isEmpty ? 1 : _items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final newItem = item.copyWith(id: newId);
    _items.add(newItem);
    return newId;
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
    }
  }

  @override
  Future<void> deleteMenuItem(int id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> resetToDefaults() async {
    _items.clear();
    _items.addAll(defaultMenuItems);
  }
}
