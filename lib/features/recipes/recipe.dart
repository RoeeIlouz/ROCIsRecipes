import 'package:flutter/foundation.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';

@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.ingredientId,
    this.quantity,
    this.unit,
    this.optional = false,
  });

  final String ingredientId;
  final double? quantity;
  final String? unit;
  final bool optional;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        ingredientId: json['ingredientId'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        optional: json['optional'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        'optional': optional,
      };

  @override
  bool operator ==(Object other) =>
      other is RecipeIngredient &&
      other.ingredientId == ingredientId &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.optional == optional;

  @override
  int get hashCode => Object.hash(ingredientId, quantity, unit, optional);
}

@immutable
class RecipeStep {
  const RecipeStep({required this.textHe, this.textEn, this.timerSeconds});

  final String textHe;
  final String? textEn;
  final int? timerSeconds;

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        textHe: json['textHe'] as String,
        textEn: json['textEn'] as String?,
        timerSeconds: (json['timerSeconds'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'textHe': textHe,
        if (textEn != null) 'textEn': textEn,
        if (timerSeconds != null) 'timerSeconds': timerSeconds,
      };

  @override
  bool operator ==(Object other) =>
      other is RecipeStep &&
      other.textHe == textHe &&
      other.textEn == textEn &&
      other.timerSeconds == timerSeconds;

  @override
  int get hashCode => Object.hash(textHe, textEn, timerSeconds);
}

@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.titleHe,
    this.titleEn,
    required this.ingredients,
    required this.steps,
    this.appliances = const {},
    required this.totalMinutes,
    this.isUserCreated = false,
    this.imagePath,
  });

  final String id;
  final String titleHe;
  final String? titleEn;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final Set<Appliance> appliances;
  final int totalMinutes;
  final bool isUserCreated;
  final String? imagePath;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        titleHe: json['titleHe'] as String,
        titleEn: json['titleEn'] as String?,
        ingredients: (json['ingredients'] as List<dynamic>)
            .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        steps: (json['steps'] as List<dynamic>)
            .map((e) => RecipeStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        appliances: ((json['appliances'] as List<dynamic>?) ?? const [])
            .map((e) => applianceFromName(e as String))
            .whereType<Appliance>()
            .toSet(),
        totalMinutes: (json['totalMinutes'] as num).toInt(),
        isUserCreated: json['isUserCreated'] as bool? ?? false,
        imagePath: json['imagePath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleHe': titleHe,
        if (titleEn != null) 'titleEn': titleEn,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        'appliances': appliances.map((e) => e.name).toList(),
        'totalMinutes': totalMinutes,
        'isUserCreated': isUserCreated,
        if (imagePath != null) 'imagePath': imagePath,
      };

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.titleHe == titleHe &&
      other.titleEn == titleEn &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.steps, steps) &&
      setEquals(other.appliances, appliances) &&
      other.totalMinutes == totalMinutes &&
      other.isUserCreated == isUserCreated &&
      other.imagePath == imagePath;

  @override
  int get hashCode => Object.hash(id, titleHe, titleEn, ingredients.length, steps.length, totalMinutes);
}
