import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

/// The planner over the app's real recipe pack and bundled prices (not hand made fixtures).
void main() {
  final recipes =
      (jsonDecode(File('assets/recipes/starter_he.json').readAsStringSync())
              as List)
          .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  final snapshot = PriceSnapshot.fromGzipBytes(
    File('assets/prices/snapshot.json.gz').readAsBytesSync(),
  );
  // The branch that prices the most ingredients, so the test does not depend on location.
  final store = ([
    ...snapshot.stores,
  ]..sort((a, b) => b.prices.length.compareTo(a.prices.length))).first;
  const staples = {'salt', 'pepper', 'oil', 'water', 'olive_oil'};
  final kitchen = {Appliance.stovetop, Appliance.oven, Appliance.microwave};

  List<String?> plan(double? budget, {Set<String> pantry = const {}}) =>
      generateWeekPlan(
        recipes: recipes,
        pantryIds: pantry,
        stapleIds: staples,
        appliances: kitchen,
        maxMinutes: 45,
        store: store,
        budget: budget,
        seed: 1,
      );

  PlanSummary summary(List<String?> p, {Set<String> pantry = const {}}) =>
      summarizePlan(
        p,
        recipes,
        pantryIds: pantry,
        stapleIds: staples,
        store: store,
      );

  test('a week is filled from the real pack with no repeated dish', () {
    final p = plan(null);
    expect(p.whereType<String>(), hasLength(7));
    expect(p.whereType<String>().toSet(), hasLength(7));
  });

  test('a real week stays inside the budget it was given', () {
    for (final budget in [60.0, 120.0, 250.0]) {
      final p = plan(budget);
      expect(summary(p).total, lessThanOrEqualTo(budget), reason: '$budget');
    }
  });

  test('a bigger budget never gives a smaller menu', () {
    final small = plan(60).whereType<String>().length;
    final big = plan(250).whereType<String>().length;
    expect(big, greaterThanOrEqualTo(small));
    expect(big, 7);
  });

  test('a stocked pantry makes the week cheaper', () {
    final pantry = {'rice', 'pasta', 'onion', 'garlic', 'potato', 'egg'};
    final bare = summary(plan(null)).total;
    final stocked = summary(plan(null, pantry: pantry), pantry: pantry).total;
    expect(stocked, lessThan(bare));
  });

  test('every planned dish fits the time and appliances', () {
    final byId = {for (final r in recipes) r.id: r};
    for (final id in plan(200).whereType<String>()) {
      final r = byId[id]!;
      expect(r.totalMinutes, lessThanOrEqualTo(45));
      expect(kitchen.containsAll(r.appliances), isTrue);
      expect(kPlanMealTypes, contains(r.mealType));
    }
  });
}
