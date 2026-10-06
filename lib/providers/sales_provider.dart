import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/sales_repository.dart';
import '../models/menu_item.dart';
import '../models/sale_entity.dart';

class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository;
  List<SaleEntity> _sales = [];
  bool _isLoading = false;

  SalesProvider({SalesRepository? repository})
      : _repository = repository ?? SqliteSalesRepository() {
    loadSales();
  }

  List<SaleEntity> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sales = await _repository.getAllSales();
    } catch (e) {
      debugPrint('Error loading sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSale({
    required int itemId,
    required String itemName,
    required int itemPrice,
    required int quantity,
    required PaymentType paymentType,
    int cashAmount = 0,
    int upiAmount = 0,
  }) async {
    if (quantity < 1 || quantity > 99 || itemPrice <= 0) return;

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final total = itemPrice * quantity;

    if (paymentType == PaymentType.mixed) {
      if (cashAmount <= 0 ||
          upiAmount <= 0 ||
          cashAmount + upiAmount != total) {
        return;
      }
    }

    final sale = SaleEntity(
      timestamp: timestamp,
      dateKey: dateKey,
      itemId: itemId,
      itemName: itemName,
      itemPrice: itemPrice,
      quantity: quantity,
      total: total,
      paymentType: paymentType.label,
      cashAmount: paymentType == PaymentType.cash ? total : cashAmount,
      upiAmount: paymentType == PaymentType.upi ? total : upiAmount,
    );

    await _repository.addSale(sale);
    await loadSales();
  }

  Future<void> addOrder({
    required List<OrderItem> items,
    required PaymentType paymentType,
    int cashAmount = 0,
    int upiAmount = 0,
  }) async {
    final validItems = items
        .where((oi) => oi.quantity >= 1 && oi.quantity <= 99 && oi.item.price > 0)
        .toList();

    if (validItems.isEmpty) return;

    final orderTotal =
        validItems.fold<int>(0, (sum, oi) => sum + (oi.item.price * oi.quantity));

    if (paymentType == PaymentType.mixed) {
      if (cashAmount <= 0 ||
          upiAmount <= 0 ||
          cashAmount + upiAmount != orderTotal) {
        return;
      }
    }

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    if (paymentType != PaymentType.mixed) {
      for (final orderItem in validItems) {
        final itemTotal = orderItem.item.price * orderItem.quantity;
        await _repository.addSale(
          SaleEntity(
            timestamp: timestamp,
            dateKey: dateKey,
            itemId: orderItem.item.id,
            itemName: orderItem.item.name,
            itemPrice: orderItem.item.price,
            quantity: orderItem.quantity,
            total: itemTotal,
            paymentType: paymentType.label,
            cashAmount: paymentType == PaymentType.cash ? itemTotal : 0,
            upiAmount: paymentType == PaymentType.upi ? itemTotal : 0,
          ),
        );
      }
    } else {
      var remainingCash = cashAmount;
      var remainingUpi = upiAmount;

      for (var i = 0; i < validItems.length; i++) {
        final orderItem = validItems[i];
        final itemTotal = orderItem.item.price * orderItem.quantity;
        final isLast = i == validItems.length - 1;

        final itemCash = isLast
            ? remainingCash
            : ((itemTotal / orderTotal) * cashAmount).toInt();
        final itemUpi = isLast
            ? remainingUpi
            : min(itemTotal - itemCash, remainingUpi);

        remainingCash = max(0, remainingCash - itemCash);
        remainingUpi = max(0, remainingUpi - itemUpi);

        await _repository.addSale(
          SaleEntity(
            timestamp: timestamp,
            dateKey: dateKey,
            itemId: orderItem.item.id,
            itemName: orderItem.item.name,
            itemPrice: orderItem.item.price,
            quantity: orderItem.quantity,
            total: itemTotal,
            paymentType: PaymentType.mixed.label,
            cashAmount: itemCash,
            upiAmount: itemUpi,
          ),
        );
      }
    }

    await loadSales();
  }

  Future<void> deleteSale(int id) async {
    await _repository.deleteSale(id);
    await loadSales();
  }

  Future<void> deleteBill(List<int> saleIds) async {
    for (final id in saleIds) {
      await _repository.deleteSale(id);
    }
    await loadSales();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadSales();
  }

  Future<int> restoreSales(List<SaleEntity> salesToRestore, {bool replace = false}) async {
    if (salesToRestore.isEmpty) return 0;
    if (replace) {
      await _repository.clearAll();
      await _repository.insertBatch(salesToRestore);
      await loadSales();
      return salesToRestore.length;
    } else {
      final existingKeys = _sales.map((s) => '${s.timestamp}_${s.itemId}').toSet();
      final toAdd = salesToRestore
          .where((s) => !existingKeys.contains('${s.timestamp}_${s.itemId}'))
          .toList();
      if (toAdd.isNotEmpty) {
        await _repository.insertBatch(toAdd);
        await loadSales();
      }
      return toAdd.length;
    }
  }
}
