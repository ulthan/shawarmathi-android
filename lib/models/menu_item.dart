class MenuItem {
  final int id;
  final String name;
  final int price;
  final String category;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.category = 'Shawarma',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'price': price,
      'category': category,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'Shawarma',
    );
  }

  MenuItem copyWith({
    int? id,
    String? name,
    int? price,
    String? category,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          category == other.category;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ price.hashCode ^ category.hashCode;
}

class OrderItem {
  final MenuItem item;
  int quantity;

  OrderItem({
    required this.item,
    required this.quantity,
  });

  int get total => item.price * quantity;
}

enum PaymentType {
  cash,
  upi,
  mixed;

  String get label {
    switch (this) {
      case PaymentType.cash:
        return 'CASH';
      case PaymentType.upi:
        return 'UPI';
      case PaymentType.mixed:
        return 'MIXED';
    }
  }

  static PaymentType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CASH':
        return PaymentType.cash;
      case 'UPI':
        return PaymentType.upi;
      case 'MIXED':
        return PaymentType.mixed;
      default:
        return PaymentType.cash;
    }
  }
}

const List<MenuItem> menuItems = [
  MenuItem(id: 1,  name: 'Shawarma Sarook',                                price: 120, category: 'Sarook'),
  MenuItem(id: 2,  name: 'Shawarma Sarook Cheese',                         price: 140, category: 'Sarook'),
  MenuItem(id: 3,  name: 'Shawarma Sarook Full Meat / Extra Meat',         price: 200, category: 'Sarook'),
  MenuItem(id: 4,  name: 'Shawarma Sarook Cheese Full Meat / Extra Meat',  price: 220, category: 'Sarook'),
  MenuItem(id: 5,  name: 'Shawarma Arabi',                                 price: 190, category: 'Arabi'),
  MenuItem(id: 6,  name: 'Shawarma Arabi Cheese',                          price: 210, category: 'Arabi'),
  MenuItem(id: 7,  name: 'Shawarma Arabi Double',                          price: 330, category: 'Arabi'),
  MenuItem(id: 8,  name: 'Shawarma Arabi Double Cheese',                   price: 370, category: 'Arabi'),
  MenuItem(id: 9,  name: 'Shawarma Bashka',                                price: 240, category: 'Platters'),
  MenuItem(id: 10, name: 'Shawarma Bashka Cheese',                         price: 280, category: 'Platters'),
  MenuItem(id: 11, name: 'Shawarma Sahan',                                 price: 260, category: 'Platters'),
  MenuItem(id: 12, name: 'French Fries',                                   price: 100, category: 'Sides'),
  MenuItem(id: 13, name: 'Loaded Fries',                                   price: 170, category: 'Sides'),
  MenuItem(id: 14, name: 'Water (500ml)',                          price: 10,  category: 'Drinks'),
  MenuItem(id: 15, name: 'Water (1L)',                             price: 20,  category: 'Drinks'),
  MenuItem(id: 16, name: 'Grape',                                  price: 100, category: 'Drinks'),
  MenuItem(id: 17, name: 'Passion Fruit',                          price: 100, category: 'Drinks'),
  MenuItem(id: 18, name: 'Watermelon Juice',                        price: 50,  category: 'Juices'),
  MenuItem(id: 19, name: 'Pineapple Juice',                         price: 60,  category: 'Juices'),
  MenuItem(id: 20, name: 'Lime Juice',                              price: 20,  category: 'Juices'),
  MenuItem(id: 21, name: 'Mint Lime',                               price: 30,  category: 'Juices'),
  MenuItem(id: 22, name: 'Pineapple Lime',                          price: 30,  category: 'Juices'),
  MenuItem(id: 23, name: 'Pepsi',                                   price: 20,  category: 'Cool Drinks'),
  MenuItem(id: 24, name: 'Dew',                                     price: 20,  category: 'Cool Drinks'),
  MenuItem(id: 25, name: '7UP',                                     price: 20,  category: 'Cool Drinks'),
];

const List<MenuItem> defaultMenuItems = menuItems;
