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

  Future<void> upsert(Recipe recipe) async {
    await _box.put(recipe.id, recipe.toJson());
    notifyListeners();
  }
}
