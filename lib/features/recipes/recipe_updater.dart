import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/starter_recipe_loader.dart';

/// Where new recipe packs are published (the `data` branch of the project repo, next to the prices).
final Uri kRecipeManifestUrl = Uri.parse(
  'https://raw.githubusercontent.com/RoeeIlouz/ROCIsRecipes/data/recipes_manifest.json',
);
final Uri kRecipePackUrl = Uri.parse(
  'https://raw.githubusercontent.com/RoeeIlouz/ROCIsRecipes/data/recipes.json.gz',
);

/// How often the app looks for new recipes by itself.
const Duration kRecipeCheckEvery = Duration(hours: 12);

bool shouldCheckForRecipes(DateTime? lastCheck, DateTime now) =>
    lastCheck == null || now.difference(lastCheck) >= kRecipeCheckEvery;

abstract class RecipePackSource {
  /// The manifest text, or null when it cannot be loaded. Never throws.
  Future<String?> fetchManifest();

  /// The gzip pack bytes, or null when they cannot be loaded. Never throws.
  Future<List<int>?> fetchPack();
}

class HttpRecipePackSource implements RecipePackSource {
  HttpRecipePackSource(this.client);

  final http.Client client;

  Future<http.Response?> _get(Uri url) async {
    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 ? response : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> fetchManifest() async =>
      (await _get(kRecipeManifestUrl))?.body;

  @override
  Future<List<int>?> fetchPack() async =>
      (await _get(kRecipePackUrl))?.bodyBytes;
}

enum RecipeUpdateStatus { updated, upToDate, failed }

class RecipeUpdateResult {
  const RecipeUpdateResult(this.status, {this.version});

  final RecipeUpdateStatus status;

  /// The pack version now in use.
  final int? version;
}

/// Downloads a newer recipe pack and swaps it in. A pack is applied only when it is newer than the one
/// in use, matches its checksum and passes the same strict validation as the bundled recipes; any
/// problem leaves the recipes exactly as they were. The user's own recipes are never touched.
class RecipeUpdater {
  RecipeUpdater({
    required this.source,
    required this.recipes,
    required this.settings,
    required this.catalog,
  });

  final RecipePackSource source;
  final RecipeRepository recipes;
  final SettingsRepository settings;
  final IngredientCatalog catalog;

  Future<RecipeUpdateResult> update() async {
    const failed = RecipeUpdateResult(RecipeUpdateStatus.failed);
    final current = settings.starterVersion;
    try {
      final manifestText = await source.fetchManifest();
      if (manifestText == null) return failed;
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      final version = manifest['version'] as int;
      if (version <= current) {
        return RecipeUpdateResult(
          RecipeUpdateStatus.upToDate,
          version: current,
        );
      }

      final bytes = await source.fetchPack();
      if (bytes == null) return failed;
      if (sha256.convert(bytes).toString() != manifest['sha256']) return failed;

      final text = utf8.decode(gzip.decode(bytes));
      if (StarterRecipeLoader.validateJson(text).isNotEmpty) return failed;
      final pack = StarterRecipeLoader.parse(text);
      if (pack.isEmpty || pack.length != manifest['count']) return failed;
      if (StarterRecipeLoader.validate(
        pack,
        catalog,
        strict: true,
      ).isNotEmpty) {
        return failed;
      }

      await recipes.syncStarter(pack);
      await recipes.retireStarter({for (final r in pack) r.id});
      await settings.setStarterVersion(version);
      return RecipeUpdateResult(RecipeUpdateStatus.updated, version: version);
    } catch (_) {
      return failed;
    }
  }

  /// Checks in the background at most every [kRecipeCheckEvery]; remembers when it last looked.
  Future<void> checkInBackground(DateTime now) async {
    if (!shouldCheckForRecipes(settings.lastRecipeCheck, now)) return;
    await settings.setLastRecipeCheck(now);
    await update();
  }
}
