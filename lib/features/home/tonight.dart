import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';

enum Greeting { morning, afternoon, evening, night }

/// "Good morning" until noon, afternoon until 5 pm, evening until 10 pm, then night.
Greeting greetingFor(int hour) {
  if (hour >= 5 && hour < 12) return Greeting.morning;
  if (hour >= 12 && hour < 17) return Greeting.afternoon;
  if (hour >= 17 && hour < 22) return Greeting.evening;
  return Greeting.night;
}

/// Why a dish is suggested for tonight.
enum TonightReason {
  /// It is on today's line of the weekly menu.
  plan,

  /// The kitchen has everything it needs.
  cookNow,

  /// Only a few ingredients are missing.
  almost,
}

class Tonight {
  const Tonight(this.recipe, this.reason, {this.missing = 0});

  final Recipe recipe;
  final TonightReason reason;

  /// Ingredients still to buy (0 unless [reason] is [TonightReason.almost]).
  final int missing;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The dish to put in front of the user tonight: today's dish from the weekly menu when it has one,
/// else the quickest main meal the kitchen already covers, else the main meal missing the fewest
/// ingredients (up to three). Null when nothing is close.
Tonight? pickTonight({
  required List<Recipe> recipes,
  required List<String?> plan,
  required DateTime? planStart,
  required DateTime now,
  required Set<String> pantryIds,
  required Set<String> stapleIds,
  required int maxMinutes,
  Set<Appliance>? appliances,
}) {
  final byId = {for (final r in recipes) r.id: r};
  if (planStart != null) {
    final index = _day(now).difference(_day(planStart)).inDays;
    if (index >= 0 && index < plan.length) {
      final id = plan[index];
      final planned = id == null ? null : byId[id];
      if (planned != null) return Tonight(planned, TonightReason.plan);
    }
  }
  final meals = [
    for (final r in recipes)
      if (kPlanMealTypes.contains(r.mealType)) r,
  ];
  List<RecipeMatch> match(MatchMode mode) => RecipeMatcher.match(
    recipes: meals,
    pantryIds: pantryIds,
    stapleIds: stapleIds,
    appliances: appliances ?? {...Appliance.values},
    maxMinutes: maxMinutes,
    mode: mode,
  );
  final ready = match(MatchMode.cookNow);
  if (ready.isNotEmpty)
    return Tonight(ready.first.recipe, TonightReason.cookNow);
  final close = match(MatchMode.almostThere);
  if (close.isNotEmpty) {
    return Tonight(
      close.first.recipe,
      TonightReason.almost,
      missing: close.first.missingIngredientIds.length,
    );
  }
  return null;
}
