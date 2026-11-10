import 'package:flutter/foundation.dart';

@immutable
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    this.ingredientId,
    required this.label,
    this.quantity,
    this.unit,
    this.checked = false,
  });

  final String id;
  final String? ingredientId;
  final String label;
  final double? quantity;
  final String? unit;
  final bool checked;

  ShoppingItem copyWith({
    String? label,
    double? quantity,
    String? unit,
    bool? checked,
  }) => ShoppingItem(
    id: id,
    ingredientId: ingredientId,
    label: label ?? this.label,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    checked: checked ?? this.checked,
  );

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    ingredientId: json['ingredientId'] as String?,
    label: json['label'] as String,
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    checked: json['checked'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (ingredientId != null) 'ingredientId': ingredientId,
    'label': label,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    'checked': checked,
  };

  @override
  bool operator ==(Object other) =>
      other is ShoppingItem &&
      other.id == id &&
      other.ingredientId == ingredientId &&
      other.label == label &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.checked == checked;

  @override
  int get hashCode =>
      Object.hash(id, ingredientId, label, quantity, unit, checked);
}
