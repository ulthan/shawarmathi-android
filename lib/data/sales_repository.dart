import 'package:sqflite/sqflite.dart';
import '../models/sale_entity.dart';
import 'database_helper.dart';

abstract class SalesRepository {
  Future<List<SaleEntity>> getAllSales();
  Future<List<SaleEntity>> getSalesByDate(String dateKey);
  Future<List<SaleEntity>> getSalesSince(String startDate);
  Future<int> addSale(SaleEntity sale);
  Future<void> insertBatch(List<SaleEntity> sales);
  Future<void> deleteSale(int id);
  Future<void> clearAll();
}

class SqliteSalesRepository implements SalesRepository {
  final DatabaseHelper _dbHelper;

  SqliteSalesRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<SaleEntity>> getAllSales() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => SaleEntity.fromMap(map)).toList();
  }

  @override
  Future<List<SaleEntity>> getSalesByDate(String dateKey) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'dateKey = ?',
      whereArgs: [dateKey],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => SaleEntity.fromMap(map)).toList();
  }

  @override
  Future<List<SaleEntity>> getSalesSince(String startDate) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'dateKey >= ?',
      whereArgs: [startDate],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => SaleEntity.fromMap(map)).toList();
  }

  @override
  Future<int> addSale(SaleEntity sale) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'sales',
      sale.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> insertBatch(List<SaleEntity> sales) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final sale in sales) {
      batch.insert(
        'sales',
        sale.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteSale(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('sales');
  }
}
