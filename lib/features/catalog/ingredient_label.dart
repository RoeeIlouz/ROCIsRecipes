import 'package:flutter/widgets.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';

/// Display name of an ingredient in the current locale. Falls back to
/// [fallback] (e.g. a custom item's saved label), then to the id.
String ingredientLabel(
  BuildContext context,
  IngredientCatalog catalog,
  String id, {
  String? fallback,
}) {
  final ing = catalog.byId(id);
  if (ing == null) {
    return fallback ?? (id.startsWith('custom:') ? id.substring(7) : id);
  }
  final isHebrew = Localizations.localeOf(context).languageCode == 'he';
  return (isHebrew || ing.nameEn.isEmpty) ? ing.nameHe : ing.nameEn;
}
