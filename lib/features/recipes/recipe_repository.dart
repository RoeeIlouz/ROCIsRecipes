import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

class RecipeRepository extends ChangeNotifier {
  RecipeRepository(this._box);

  final Box<Map> _box;

  List<Recipe> get all => _box.values
      .map((m) => Recipe.fromJson(Map<String, dynamic>.from(m)))
      .toList(growable: false);

  Recipe? byId(String id) {
    final m = _box.get(id);
    return m == null ? null : Recipe.fromJson(Map<String, dynamic>.from(m));
  }

  Future<void> seedIfEmpty(List<Recipe> recipes) async {
    if (_box.isNotEmpty) return;
    await _box.putAll({for (final r in recipes) r.id: r.toJson()});
    notifyListeners();
  }

  /// Adds or updates built-in recipes by id. User-created recipes, including
  /// one that shares an id with a starter recipe, are never overwritten.
  Future<void> syncStarter(List<Recipe> starter) async {
    final updates = <String, Map<String, dynamic>>{};
    for (final r in starter) {
      final existing = byId(r.id);
      if (existing != null && existing.isUserCreated) continue;
      updates[r.id] = r.toJson();
    }
    if (updates.isEmpty) return;
    await _box.putAll(updates);
    notifyListeners();
  }

  /// Removes built-in recipes that are no longer part of the shipped pack.
  /// User-created recipes are never removed.
  Future<void> retireStarter(Set<String> keepIds) async {
    final stale = all
        .where((r) => !r.isUserCreated && !keepIds.contains(r.id))
        .map((r) => r.id)
        .toList();
    if (stale.isEmpty) return;
    await _box.deleteAll(stale);
    notifyListeners();
  }

  Future<void> upsert(Recipe recipe) async {
    await _box.put(recipe.id, recipe.toJson());
    notifyListeners();
  }
}
