class Product {
  final String id;
  String name;
  double calories; // per unit
  String unit;
  String emoji;

  Product({
    required this.id,
    required this.name,
    required this.calories,
    this.unit = 'serving',
    this.emoji = '🍽️',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'calories': calories, 'unit': unit, 'emoji': emoji};

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        calories: (j['calories'] as num).toDouble(),
        unit: (j['unit'] as String?) ?? 'serving',
        emoji: (j['emoji'] as String?) ?? '🍽️',
      );
}

/// A logged food on a given day. Name/calories are copied so history
/// stays correct even if the food is edited or deleted later.
class Entry {
  final String id;
  final String productId;
  final String name;
  final String emoji;
  final String unit;
  final double calories;
  double quantity;

  Entry({
    required this.id,
    required this.productId,
    required this.name,
    required this.emoji,
    required this.unit,
    required this.calories,
    required this.quantity,
  });

  double get total => calories * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'emoji': emoji,
        'unit': unit,
        'calories': calories,
        'quantity': quantity,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: (j['id'] as String?) ?? '${j['productId']}_${j['quantity']}',
        productId: j['productId'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '🍽️',
        unit: (j['unit'] as String?) ?? 'serving',
        calories: (j['calories'] as num).toDouble(),
        quantity: (j['quantity'] as num).toDouble(),
      );
}
