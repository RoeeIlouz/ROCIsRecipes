import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/starter_recipe_loader.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/shared/ui/theme/theme_service.dart';

class AppInitializer {
  /// Initializes core engine, local database, and returns root providers.
  static Future<List<SingleChildWidget>> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    await Hive.initFlutter();

    final themeService = ThemeService();
    await themeService.init();

    final catalog = IngredientCatalog.fromJson(
      await rootBundle.loadString('assets/data/ingredients.json'),
    );
    final pantry = PantryRepository(await Hive.openBox<Map>('pantry'));
    final recipes = RecipeRepository(await Hive.openBox<Map>('recipes'));
    final shopping = ShoppingRepository(await Hive.openBox<Map>('shopping'));
    final settings = SettingsRepository(await Hive.openBox('app_settings'));
    await settings.seedStaplesIfUnset(catalog.defaultStapleIds);
    await recipes.seedIfEmpty(
      StarterRecipeLoader.parse(await rootBundle.loadString('assets/recipes/starter_he.json')),
    );

    return [
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      Provider<IngredientCatalog>.value(value: catalog),
      ChangeNotifierProvider<PantryRepository>.value(value: pantry),
      ChangeNotifierProvider<RecipeRepository>.value(value: recipes),
      ChangeNotifierProvider<ShoppingRepository>.value(value: shopping),
      ChangeNotifierProvider<SettingsRepository>.value(value: settings),
    ];
  }
}
