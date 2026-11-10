import 'package:rocis_recipes/features/recipes/recipe.dart';

/// Protein filter choices, in display order. `vegetarian` means no meat or fish at all.
const List<String> kProteinKinds = ['chicken', 'beef', 'fish', 'vegetarian'];

const _chicken = {
  'chicken',
  'chicken_breast',
  'schnitzel',
  'ground_turkey',
  'turkey_breast',
};
const _beef = {'beef', 'ground_beef', 'sausage'};
const _fish = {'salmon', 'tuna', 'white_fish', 'sardines'};

/// Which proteins a recipe is built on, from its required ingredients (optional ones do not count).
/// A recipe with none of them is `vegetarian`.
Set<String> proteinKinds(Recipe recipe) {
  final kinds = <String>{};
  for (final i in recipe.ingredients) {
    if (i.optional) continue;
    if (_chicken.contains(i.ingredientId)) kinds.add('chicken');
    if (_beef.contains(i.ingredientId)) kinds.add('beef');
    if (_fish.contains(i.ingredientId)) kinds.add('fish');
  }
  return kinds.isEmpty ? {'vegetarian'} : kinds;
}

/// All the suggestion filters together; a null or false filter lets everything through.
bool matchesFilters(
  Recipe recipe, {
  String? meal,
  String? protein,
  bool mealPrepOnly = false,
}) {
  if (meal != null && recipe.mealType != meal) return false;
  if (protein != null && !proteinKinds(recipe).contains(protein)) return false;
  if (mealPrepOnly && !recipe.mealPrep) return false;
  return true;
}
