import 'dart:convert';

import 'package:rocis_recipes/core/text/hebrew_normalizer.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';

class IngredientCatalog {
  IngredientCatalog(List<Ingredient> items) : all = List.unmodifiable(items) {
    for (final item in all) {
      _byId[item.id] = item;
      final keys = <String>{};
      for (final name in [item.nameHe, item.nameEn, ...item.synonyms]) {
        final key = normalizeText(name);
        if (key.isNotEmpty) keys.add(key);
      }
      _keys[item.id] = keys.toList();
      for (final key in keys) {
        _index.putIfAbsent(key, () => item);
      }
    }
  }

  factory IngredientCatalog.fromJson(String json) => IngredientCatalog(
        (jsonDecode(json) as List<dynamic>)
            .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final List<Ingredient> all;
  final Map<String, Ingredient> _byId = {};
  final Map<String, Ingredient> _index = {};
  final Map<String, List<String>> _keys = {};

  Ingredient? byId(String id) => _byId[id];

  Ingredient? resolve(String text) => _index[normalizeText(text)];

  Ingredient resolveOrCustom(String text) {
    final found = resolve(text);
    if (found != null) return found;
    final key = normalizeText(text);
    return Ingredient(id: 'custom:$key', nameHe: text.trim(), nameEn: '');
  }

  List<Ingredient> search(String prefix, {int limit = 8}) {
    final p = normalizeText(prefix);
    if (p.isEmpty) return const [];
    final out = <Ingredient>[];
    for (final item in all) {
      if (_keys[item.id]!.any((k) => k.startsWith(p))) {
        out.add(item);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  Set<String> get defaultStapleIds => {
        for (final i in all)
          if (i.isStaple) i.id,
      };
}
