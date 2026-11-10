import 'package:flutter/foundation.dart';

@immutable
class Ingredient {
  const Ingredient({
    required this.id,
    required this.nameHe,
    required this.nameEn,
    this.synonyms = const [],
    this.isStaple = false,
    this.category,
  });

  final String id;
  final String nameHe;
  final String nameEn;
  final List<String> synonyms;
  final bool isStaple;

  /// One of kIngredientCategories (see ingredient_icons.dart); null for custom items.
  final String? category;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        nameHe: json['nameHe'] as String,
        nameEn: json['nameEn'] as String? ?? '',
        synonyms: ((json['synonyms'] as List<dynamic>?) ?? const []).cast<String>(),
        isStaple: json['isStaple'] as bool? ?? false,
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameHe': nameHe,
        'nameEn': nameEn,
        'synonyms': synonyms,
        'isStaple': isStaple,
        if (category != null) 'category': category,
      };

  @override
  bool operator ==(Object other) =>
      other is Ingredient &&
      other.id == id &&
      other.nameHe == nameHe &&
      other.nameEn == nameEn &&
      listEquals(other.synonyms, synonyms) &&
      other.isStaple == isStaple &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, nameHe, nameEn, isStaple);
}
