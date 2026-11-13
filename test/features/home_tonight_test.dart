import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/home/tonight.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

Recipe _r(
  String id,
  List<String> ings, {
  int minutes = 20,
  String meal = 'dinner',
}) => Recipe(
  id: id,
  titleHe: id,
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: minutes,
  mealType: meal,
);

void main() {
  final today = DateTime(2026, 11, 13, 19);
  final planned = _r('planned', ['rice']);
  final ready = _r('ready', ['egg'], minutes: 15);
  final readySlow = _r('ready_slow', ['egg'], minutes: 40);
  final close = _r('close', ['egg', 'milk']);
  final far = _r('far', ['a', 'b', 'c', 'd']);

  Tonight? pick({
    List<Recipe>? recipes,
    List<String?> plan = const [],
    DateTime? planStart,
    Set<String> pantry = const {'egg'},
  }) => pickTonight(
    recipes: recipes ?? [planned, ready, readySlow, close, far],
    plan: plan,
    planStart: planStart,
    now: today,
    pantryIds: pantry,
    stapleIds: const {'salt'},
    maxMinutes: 60,
  );

  test('tonight comes from the weekly menu when it covers today', () {
    final t = pick(
      plan: [null, 'planned', null],
      planStart: DateTime(2026, 11, 12),
    );
    expect(t!.recipe.id, 'planned');
    expect(t.reason, TonightReason.plan);
  });

  test('the menu day is counted from the day it started, not the hour', () {
    final t = pick(plan: ['planned'], planStart: DateTime(2026, 11, 13, 6));
    expect(t!.recipe.id, 'planned');
  });

  test('a menu that has run out, or a skipped or empty day, is ignored', () {
    expect(
      pick(plan: ['planned'], planStart: DateTime(2026, 11, 1))!.reason,
      TonightReason.cookNow,
    );
    expect(
      pick(plan: [kSkippedDay], planStart: DateTime(2026, 11, 13))!.reason,
      TonightReason.cookNow,
    );
    expect(
      pick(plan: [null], planStart: DateTime(2026, 11, 13))!.reason,
      TonightReason.cookNow,
    );
    expect(
      pick(plan: ['gone'], planStart: DateTime(2026, 11, 13))!.reason,
      TonightReason.cookNow,
    );
  });

  test('without a menu the quickest dish the pantry covers is suggested', () {
    final t = pick();
    expect(t!.recipe.id, 'ready');
    expect(t.reason, TonightReason.cookNow);
    expect(t.missing, 0);
  });

  test('when nothing is fully covered the closest dish is suggested', () {
    final t = pick(pantry: const {});
    expect(t!.reason, TonightReason.almost);
    expect(t.missing, greaterThan(0));
    expect(t.missing, lessThanOrEqualTo(3));
  });

  test('there is nothing to suggest when no dish is close', () {
    expect(pick(recipes: [far], pantry: const {}), isNull);
    expect(pick(recipes: const []), isNull);
  });

  test('only main meals are suggested for tonight', () {
    final cake = _r('cake', ['egg'], meal: 'dessert');
    expect(pick(recipes: [cake]), isNull);
  });

  test('the greeting follows the time of day', () {
    expect(greetingFor(7), Greeting.morning);
    expect(greetingFor(12), Greeting.afternoon);
    expect(greetingFor(16), Greeting.afternoon);
    expect(greetingFor(18), Greeting.evening);
    expect(greetingFor(21), Greeting.evening);
    expect(greetingFor(23), Greeting.night);
    expect(greetingFor(3), Greeting.night);
  });
}
