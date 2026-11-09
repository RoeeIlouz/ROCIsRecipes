import 'package:flutter/foundation.dart';

@immutable
class PantryItem {
  const PantryItem({required this.ingredientId, this.quantity, this.unit});

  final String ingredientId;
  final double? quantity;
  final String? unit;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        ingredientId: json['ingredientId'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
      };

  @override
  bool operator ==(Object other) =>
      other is PantryItem &&
      other.ingredientId == ingredientId &&
      other.quantity == quantity &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(ingredientId, quantity, unit);
}
