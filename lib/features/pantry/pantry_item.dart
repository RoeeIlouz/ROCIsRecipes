import 'package:flutter/foundation.dart';

@immutable
class PantryItem {
  const PantryItem({
    required this.ingredientId,
    this.quantity,
    this.unit,
    this.label,
  });

  final String ingredientId;
  final double? quantity;
  final String? unit;

  /// Display name for custom (non-catalog) ingredients, whose id is a
  /// normalized form that has lost final-letter spelling.
  final String? label;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    ingredientId: json['ingredientId'] as String,
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    label: json['label'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (label != null) 'label': label,
  };

  @override
  bool operator ==(Object other) =>
      other is PantryItem &&
      other.ingredientId == ingredientId &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.label == label;

  @override
  int get hashCode => Object.hash(ingredientId, quantity, unit, label);
}
