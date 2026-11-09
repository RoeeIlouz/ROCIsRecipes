import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';

class PantryRepository extends ChangeNotifier {
  PantryRepository(this._box);

  final Box<Map> _box;

  List<PantryItem> get items => _box.values
      .map((m) => PantryItem.fromJson(Map<String, dynamic>.from(m)))
      .toList(growable: false);

  Set<String> get ids => items.map((e) => e.ingredientId).toSet();

  Future<void> upsert(PantryItem item) async {
    await _box.put(item.ingredientId, item.toJson());
    notifyListeners();
  }

  Future<void> remove(String ingredientId) async {
    await _box.delete(ingredientId);
    notifyListeners();
  }
}
