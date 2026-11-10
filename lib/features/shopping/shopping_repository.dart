import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:rocis_recipes/core/text/hebrew_normalizer.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

class ShoppingRepository extends ChangeNotifier {
  ShoppingRepository(this._box);

  final Box<Map> _box;

  List<ShoppingItem> get items => _box.values
      .map((m) => ShoppingItem.fromJson(Map<String, dynamic>.from(m)))
      .toList(growable: false);

  Future<void> add(ShoppingItem item) async {
    await _box.put(item.id, item.toJson());
    notifyListeners();
  }

  /// Adds items, skipping any whose ingredient is already unchecked on the list.
  Future<void> addMissing(Iterable<ShoppingItem> incoming) async {
    final pending = items
        .where((e) => !e.checked && e.ingredientId != null)
        .map((e) => e.ingredientId!)
        .toSet();
    final toAdd = <String, Map<String, dynamic>>{};
    for (final item in incoming) {
      final ingredientId = item.ingredientId;
      if (ingredientId != null && !pending.add(ingredientId)) continue;
      toAdd[item.id] = item.toJson();
    }
    if (toAdd.isEmpty) return;
    await _box.putAll(toAdd);
    notifyListeners();
  }

  /// Adds [item] unless an unchecked item already covers it (same ingredient
  /// id, or same normalized label). Returns whether it was added.
  Future<bool> addIfNew(ShoppingItem item) async {
    final label = normalizeText(item.label);
    final duplicate = items.any(
      (e) =>
          !e.checked &&
          ((item.ingredientId != null && e.ingredientId == item.ingredientId) ||
              normalizeText(e.label) == label),
    );
    if (duplicate) return false;
    await add(item);
    return true;
  }

  Future<void> toggle(String id) async {
    final m = _box.get(id);
    if (m == null) return;
    final item = ShoppingItem.fromJson(Map<String, dynamic>.from(m));
    await _box.put(id, item.copyWith(checked: !item.checked).toJson());
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> clearChecked() async {
    final keys = items.where((e) => e.checked).map((e) => e.id).toList();
    if (keys.isEmpty) return;
    await _box.deleteAll(keys);
    notifyListeners();
  }
}
