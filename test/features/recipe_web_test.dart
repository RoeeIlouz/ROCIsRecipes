import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/ai/recipe_draft.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/recipe_web.dart';

import '../helpers/test_env.dart';

const _page = '''
<html><head><title>x</title>
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[
 {"@type":"WebSite","name":"Site"},
 {"@type":["Recipe","Thing"],"name":"חביתה ביתית","recipeYield":["4","4 servings"],
  "totalTime":"PT1H15M",
  "recipeIngredient":["2 ביצים","מלח","חצי כוס חלב"],
  "recipeInstructions":[
   {"@type":"HowToStep","text":"טורפים את הביצים"},
   {"@type":"HowToSection","name":"סיום","itemListElement":[
     {"@type":"HowToStep","text":"מטגנים"},{"@type":"HowToStep","text":"מגישים"}]}
  ]}
]}</script></head><body></body></html>
''';

void main() {
  final catalog = IngredientCatalog(testIngredients);

  test('a recipe is read from the page markup, nested steps included', () {
    final json = recipeJsonFromHtml(_page)!;
    expect(json['title'], 'חביתה ביתית');
    expect(json['servings'], 4);
    expect(json['minutes'], 75);
    expect(json['ingredients'], ['2 ביצים', 'מלח', 'חצי כוס חלב']);
    expect(json['steps'], ['טורפים את הביצים', 'מטגנים', 'מגישים']);
    final recipe = recipeFromAiJson(json, catalog)!;
    expect(recipe.ingredients.first.ingredientId, 'egg');
    expect(recipe.ingredients.first.quantity, 2);
  });

  test('instructions given as one text block are split into steps', () {
    final json = recipeJsonFromHtml('''
<script type="application/ld+json">
{"@type":"Recipe","name":"x","recipeIngredient":["a"],
 "recipeInstructions":"First do this.\\nThen do that.\\n\\nFinally serve."}
</script>''')!;
    expect(json['steps'], [
      'First do this.',
      'Then do that.',
      'Finally serve.',
    ]);
  });

  test('a top level list and a single quoted type are understood', () {
    final json = recipeJsonFromHtml('''
<script type='application/ld+json'>[{"@type":"Recipe","name":"y",
"recipeIngredient":["b"],"recipeInstructions":["s1","s2"],"totalTime":"PT30M"}]
</script>''')!;
    expect(json['title'], 'y');
    expect(json['minutes'], 30);
  });

  test('pages without a recipe, or with broken markup, give null', () {
    expect(recipeJsonFromHtml('<html>nothing</html>'), isNull);
    expect(
      recipeJsonFromHtml(
        '<script type="application/ld+json">{ not json</script>',
      ),
      isNull,
    );
    expect(
      recipeJsonFromHtml(
        '<script type="application/ld+json">{"@type":"Article"}</script>',
      ),
      isNull,
    );
  });

  test('ISO durations become minutes', () {
    expect(minutesFromIsoDuration('PT45M'), 45);
    expect(minutesFromIsoDuration('PT2H'), 120);
    expect(minutesFromIsoDuration('P0DT1H30M'), 90);
    expect(minutesFromIsoDuration('nonsense'), isNull);
    expect(minutesFromIsoDuration(null), isNull);
  });

  testWidgets('the editor fills itself from a pasted link', (tester) async {
    final env = await TestEnv.create();
    env.web.html = _page;
    await tester.pumpWidget(env.wrapApp('/recipe-edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor_link_import')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('link_field')),
      'https://example.com/omelette',
    );
    await tester.tap(find.byKey(const Key('link_import_confirm')));
    await tester.pumpAndSettle();
    expect(env.web.lastUri.toString(), 'https://example.com/omelette');
    final title = tester.widget<TextField>(
      find.byKey(const Key('editor_title')),
    );
    expect(title.controller!.text, 'חביתה ביתית');
  });

  testWidgets('a page without a recipe says so and leaves the editor empty', (
    tester,
  ) async {
    final env = await TestEnv.create();
    env.web.html = '<html>no recipe here</html>';
    await tester.pumpWidget(env.wrapApp('/recipe-edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor_link_import')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('link_field')),
      'example.com/none',
    );
    await tester.tap(find.byKey(const Key('link_import_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('link_import_error')), findsOneWidget);
    final title = tester.widget<TextField>(
      find.byKey(const Key('editor_title')),
    );
    expect(title.controller!.text, isEmpty);
  });
}
