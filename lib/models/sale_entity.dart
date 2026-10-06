class SaleEntity {
  final int? id;
  final int timestamp; // epoch millis
  final String dateKey; // "YYYY-MM-DD"
  final int itemId;
  final String itemName;
  final int itemPrice;
  final int quantity;
  final int total;
  final String paymentType; // "CASH" | "UPI" | "MIXED"
  final int cashAmount;
  final int upiAmount;

  const SaleEntity({
    this.id,
    required this.timestamp,
    required this.dateKey,
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
    required this.total,
    required this.paymentType,
    this.cashAmount = 0,
    this.upiAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp,
      'dateKey': dateKey,
      'itemId': itemId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'quantity': quantity,
      'total': total,
      'paymentType': paymentType,
      'cashAmount': cashAmount,
      'upiAmount': upiAmount,
    };
  }

  factory SaleEntity.fromMap(Map<String, dynamic> map) {
    return SaleEntity(
      id: map['id'] as int?,
      timestamp: (map['timestamp'] as num).toInt(),
      dateKey: map['dateKey'] as String,
      itemId: (map['itemId'] as num).toInt(),
      itemName: map['itemName'] as String,
      itemPrice: (map['itemPrice'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      total: (map['total'] as num).toInt(),
      paymentType: map['paymentType'] as String,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 0,
      upiAmount: (map['upiAmount'] as num?)?.toInt() ?? 0,
    );
  }

  SaleEntity copyWith({
    int? id,
    int? timestamp,
    String? dateKey,
    int? itemId,
    String? itemName,
    int? itemPrice,
    int? quantity,
    int? total,
    String? paymentType,
    int? cashAmount,
    int? upiAmount,
  }) {
    return SaleEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      dateKey: dateKey ?? this.dateKey,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice ?? this.itemPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      paymentType: paymentType ?? this.paymentType,
      cashAmount: cashAmount ?? this.cashAmount,
      upiAmount: upiAmount ?? this.upiAmount,
    );
  }
}
