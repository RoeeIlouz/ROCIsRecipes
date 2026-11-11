import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rocis_recipes/core/config/router.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/ai/recipe_ai.dart';
import 'package:rocis_recipes/features/recipes/photo_source.dart';
import 'package:rocis_recipes/features/recipes/recipe_web.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/features/prices/price_repository.dart';
import 'package:rocis_recipes/features/prices/price_service.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

const testIngredients = [
  Ingredient(
    id: 'tomato',
    nameHe: 'עגבנייה',
    nameEn: 'Tomato',
    synonyms: ['עגבניות'],
    category: 'produce',
  ),
  Ingredient(
    id: 'cucumber',
    nameHe: 'מלפפון',
    nameEn: 'Cucumber',
    synonyms: ['מלפפונים'],
    category: 'produce',
  ),
  Ingredient(
    id: 'egg',
    nameHe: 'ביצה',
    nameEn: 'Egg',
    synonyms: ['ביצים'],
    category: 'dairy',
  ),
  Ingredient(id: 'milk', nameHe: 'חלב', nameEn: 'Milk', category: 'dairy'),
  Ingredient(
    id: 'salt',
    nameHe: 'מלח',
    nameEn: 'Salt',
    isStaple: true,
    category: 'pantry',
  ),
];

int _counter = 0;

class _NoSnapshotSource implements SnapshotSource {
  @override
  Future<List<int>?> fetch() async => null;
}

/// Location provider with a fixed answer, for tests.
class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider({this.status = LocationStatus.granted, this.location});

  final LocationStatus status;
  final UserLocation? location;
  int requests = 0;

  @override
  Future<LocationStatus> requestPermission() async {
    requests++;
    return status;
  }

  @override
  Future<UserLocation?> currentLocation() async => location;
}

/// In-memory Hive boxes and repositories for widget tests (no disk IO).
class FakeRecipeAi implements RecipeAi {
  bool installed = true;
  bool supported = true;
  Map<String, dynamic>? recipeJson;
  List<String> names = const [];
  Object? error;
  int installs = 0;
  String? lastText;

  int warmUps = 0;

  @override
  Future<void> warmUp({bool image = false}) async => warmUps++;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  int get downloadBytes => 2 * 1024 * 1024 * 1024;

  @override
  Stream<double> install() async* {
    installs++;
    yield 50;
    installed = true;
    yield 100;
  }

  @override
  Future<Map<String, dynamic>?> readRecipe({
    String? text,
    Uint8List? image,
  }) async {
    if (error != null) throw error!;
    lastText = text;
    return recipeJson;
  }

  List<String>? lastInventIngredients;

  @override
  Future<Map<String, dynamic>?> inventRecipe({
    required List<String> ingredients,
    required int maxMinutes,
    String? mealType,
  }) async {
    if (error != null) throw error!;
    lastInventIngredients = ingredients;
    return recipeJson;
  }

  @override
  Future<List<String>> identifyIngredients(Uint8List image) async {
    if (error != null) throw error!;
    return names;
  }
}

/// Web page source with a fixed answer, for tests.
class FakeWebPageSource implements WebPageSource {
  String? html;
  Uri? lastUri;

  @override
  Future<String?> fetch(Uri uri) async {
    lastUri = uri;
    return html;
  }
}

class FakePhotoSource implements PhotoSource {
  Uint8List? nextBytes;

  @override
  Future<Uint8List?> pickBytes({required bool camera}) async {
    lastCamera = camera;
    return nextBytes;
  }

  String? next;
  bool? lastCamera;

  @override
  Future<String?> pick({required bool camera}) async {
    lastCamera = camera;
    return next;
  }
}

class TestEnv {
  TestEnv._(
    this.catalog,
    this.pantry,
    this.settings,
    this.recipes,
    this.shopping,
    this.prices,
    this.nearby,
  );

  final IngredientCatalog catalog;
  final PantryRepository pantry;
  final SettingsRepository settings;
  final RecipeRepository recipes;
  final ShoppingRepository shopping;
  final PriceRepository prices;
  final NearbyController nearby;

  /// Urls the app asked to open (for example Google Maps).
  final List<Uri> launched = [];
  final FakePhotoSource photos = FakePhotoSource();
  final FakeRecipeAi ai = FakeRecipeAi();
  final FakeWebPageSource web = FakeWebPageSource();

  static Future<TestEnv> create({
    List<Recipe> recipes = const [],
    PriceSnapshot? snapshot,
    LocationProvider? location,
  }) async {
    Hive.init(Directory.systemTemp.path);
    final n = _counter++;
    Future<Box<Map>> mapBox(String name) =>
        Hive.openBox<Map>('${name}_$n', bytes: Uint8List(0));
    final env = TestEnv._(
      IngredientCatalog(testIngredients),
      PantryRepository(await mapBox('pantry')),
      SettingsRepository(
        await Hive.openBox('settings_$n', bytes: Uint8List(0)),
      ),
      RecipeRepository(await mapBox('recipes')),
      ShoppingRepository(await mapBox('shopping')),
      PriceRepository(
        bundled:
            snapshot ??
            PriceSnapshot(
              generatedAt: DateTime.now(),
              chains: const [],
              stores: const [],
            ),
        source: _NoSnapshotSource(),
        cacheDir: Directory.systemTemp.createTempSync('rocis_test_prices_'),
      ),
      NearbyController(
        location ?? FakeLocationProvider(status: LocationStatus.denied),
      ),
    );
    await env.recipes.seedIfEmpty(recipes);
    return env;
  }

  List<SingleChildWidget> get providers => [
    Provider<IngredientCatalog>.value(value: catalog),
    ChangeNotifierProvider<PantryRepository>.value(value: pantry),
    ChangeNotifierProvider<SettingsRepository>.value(value: settings),
    ChangeNotifierProvider<RecipeRepository>.value(value: recipes),
    ChangeNotifierProvider<ShoppingRepository>.value(value: shopping),
    ChangeNotifierProvider<PriceRepository>.value(value: prices),
    ChangeNotifierProvider<NearbyController>.value(value: nearby),
    Provider<PriceService>.value(value: const PriceService()),
    Provider<PhotoSource>.value(value: photos),
    Provider<RecipeAi>.value(value: ai),
    Provider<WebPageSource>.value(value: web),
    Provider<LaunchUrl>.value(
      value: (uri) async {
        launched.add(uri);
        return true;
      },
    ),
  ];

  static const _delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget wrap(Widget child, {Locale locale = const Locale('he')}) =>
      MultiProvider(
        providers: providers,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _delegates,
          home: child,
        ),
      );

  /// Pumps the real app router at [location] (for navigation tests).
  Widget wrapApp(String location, {Locale locale = const Locale('he')}) =>
      MultiProvider(
        providers: providers,
        child: MaterialApp.router(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _delegates,
          routerConfig: buildRouter(initialLocation: location),
        ),
      );
}
