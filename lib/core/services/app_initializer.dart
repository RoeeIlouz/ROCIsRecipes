import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/features/prices/price_repository.dart';
import 'package:rocis_recipes/features/prices/price_service.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:url_launcher/url_launcher.dart';
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

/// Folder for the downloaded price snapshot. Platform channel call, so it has a
/// strict 2 second timeout; on failure a temp folder is used (the cache is optional).
Future<Directory> _priceCacheDir() async {
  try {
    final base = await getApplicationSupportDirectory().timeout(const Duration(seconds: 2));
    return Directory('${base.path}/prices');
  } catch (_) {
    return Directory('${Directory.systemTemp.path}/rocis_prices');
  }
}

class AppInitializer {
  /// Initializes core engine, local database, and returns root providers.
  static Future<List<SingleChildWidget>> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Fonts ship inside the app (google_fonts/); never fetch them over the network.
    GoogleFonts.config.allowRuntimeFetching = false;

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
    if (settings.starterVersion < kStarterVersion) {
      await recipes.syncStarter(
        StarterRecipeLoader.parse(await rootBundle.loadString('assets/recipes/starter_he.json')),
      );
      await settings.setStarterVersion(kStarterVersion);
    }

    final bundled = PriceSnapshot.fromGzipBytes(
      (await rootBundle.load('assets/prices/snapshot.json.gz')).buffer.asUint8List(),
    );
    final prices = PriceRepository(
      bundled: bundled,
      source: HttpSnapshotSource(kSnapshotUrl, http.Client()),
      cacheDir: await _priceCacheDir(),
    );
    await prices.init();
    // Refresh in the background; the app starts with the cached or bundled copy.
    unawaited(prices.refreshIfNeeded(DateTime.now()));

    return [
      ChangeNotifierProvider<PriceRepository>.value(value: prices),
      ChangeNotifierProvider<NearbyController>.value(value: NearbyController(GeolocatorLocationProvider())),
      Provider<PriceService>.value(value: const PriceService()),
      Provider<LaunchUrl>.value(
        value: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
      ),
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      Provider<IngredientCatalog>.value(value: catalog),
      ChangeNotifierProvider<PantryRepository>.value(value: pantry),
      ChangeNotifierProvider<RecipeRepository>.value(value: recipes),
      ChangeNotifierProvider<ShoppingRepository>.value(value: shopping),
      ChangeNotifierProvider<SettingsRepository>.value(value: settings),
    ];
  }
}
