import 'package:intl/intl.dart';
import 'menu_item.dart';
import 'sale_entity.dart';

class BillItem {
  final String itemName;
  final int quantity;
  final int unitPrice;
  int get total => quantity * unitPrice;

  const BillItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });
}

class BillReceipt {
  final String receiptId;
  final int timestamp;
  final String dateKey;
  final List<BillItem> items;
  final int totalAmount;
  final String paymentType;
  final int cashAmount;
  final int upiAmount;
  final List<int> saleIds;

  const BillReceipt({
    required this.receiptId,
    required this.timestamp,
    required this.dateKey,
    required this.items,
    required this.totalAmount,
    required this.paymentType,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.saleIds = const [],
  });

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  factory BillReceipt.fromSales(List<SaleEntity> sales) {
    if (sales.isEmpty) {
      throw ArgumentError('Sales list cannot be empty');
    }
    final first = sales.first;
    final items = sales.map((s) => BillItem(
      itemName: s.itemName,
      quantity: s.quantity,
      unitPrice: s.itemPrice,
    )).toList();
    final total = sales.fold<int>(0, (sum, s) => sum + s.total);
    final cash = sales.fold<int>(0, (sum, s) => sum + s.cashAmount);
    final upi = sales.fold<int>(0, (sum, s) => sum + s.upiAmount);
    final ids = sales.map((s) => s.id).whereType<int>().toList();

    final idStr = first.id != null ? '#${first.id}' : '#${first.timestamp.toString().substring(6)}';

    return BillReceipt(
      receiptId: idStr,
      timestamp: first.timestamp,
      dateKey: first.dateKey,
      items: items,
      totalAmount: total,
      paymentType: first.paymentType,
      cashAmount: cash,
      upiAmount: upi,
      saleIds: ids,
    );
  }

  static List<BillReceipt> groupSalesIntoBills(List<SaleEntity> sales) {
    final Map<int, List<SaleEntity>> grouped = {};
    for (final sale in sales) {
      grouped.putIfAbsent(sale.timestamp, () => []).add(sale);
    }
    final sortedTimestamps = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return sortedTimestamps.map((ts) => BillReceipt.fromSales(grouped[ts]!)).toList();
  }

  factory BillReceipt.fromOrder({
    required List<OrderItem> orderItems,
    required PaymentType paymentType,
    required int cashAmount,
    required int upiAmount,
    int? orderId,
  }) {
    final now = DateTime.now();
    final total = orderItems.fold<int>(0, (sum, oi) => sum + (oi.item.price * oi.quantity));
    final items = orderItems.map((oi) => BillItem(
      itemName: oi.item.name,
      quantity: oi.quantity,
      unitPrice: oi.item.price,
    )).toList();

    final idStr = orderId != null ? '#$orderId' : '#${now.millisecondsSinceEpoch.toString().substring(6)}';

    return BillReceipt(
      receiptId: idStr,
      timestamp: now.millisecondsSinceEpoch,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
      items: items,
      totalAmount: total,
      paymentType: paymentType.label,
      cashAmount: paymentType == PaymentType.cash ? total : cashAmount,
      upiAmount: paymentType == PaymentType.upi ? total : upiAmount,
    );
  }
}
