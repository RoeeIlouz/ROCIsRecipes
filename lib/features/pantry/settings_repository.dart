import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';

class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._box);

  static const _appliancesKey = 'appliances';
  static const _staplesKey = 'staples';
  static const _maxMinutesKey = 'maxMinutes';
  static const defaultMaxMinutes = 45;

  final Box _box;

  Set<Appliance> get appliances =>
      ((_box.get(_appliancesKey) as List?) ?? const [])
          .map((e) => applianceFromName(e as String))
          .whereType<Appliance>()
          .toSet();

  Future<void> setAppliances(Set<Appliance> value) async {
    await _box.put(_appliancesKey, value.map((e) => e.name).toList());
    notifyListeners();
  }

  /// Every kitchen has these; written only if the user never chose appliances.
  Future<void> seedAppliancesIfUnset() async {
    if (_box.containsKey(_appliancesKey)) return;
    await setAppliances({
      Appliance.stovetop,
      Appliance.oven,
      Appliance.microwave,
    });
  }

  Set<String> get stapleIds =>
      ((_box.get(_staplesKey) as List?) ?? const []).cast<String>().toSet();

  Future<void> setStapleIds(Set<String> value) async {
    await _box.put(_staplesKey, value.toList());
    notifyListeners();
  }

  /// Writes [defaults] only if the user has never saved a staples list.
  Future<void> seedStaplesIfUnset(Set<String> defaults) async {
    if (_box.containsKey(_staplesKey)) return;
    await setStapleIds(defaults);
  }

  /// Branch the user chose by hand per chain (chain id to branch id).
  Map<String, String> get manualStoreIds => {
    for (final e in ((_box.get('manualStores') as Map?) ?? const {}).entries)
      e.key as String: e.value as String,
  };

  Future<void> setManualStore(String chainId, String storeId) async {
    await _box.put('manualStores', {...manualStoreIds, chainId: storeId});
    notifyListeners();
  }

  /// Weekly food budget in NIS, or null when the user has not set one.
  int? get weeklyBudget => _box.get('weeklyBudget') as int?;

  Future<void> setWeeklyBudget(int? value) async {
    if (value == null) {
      await _box.delete('weeklyBudget');
    } else {
      await _box.put('weeklyBudget', value);
    }
    notifyListeners();
  }

  /// Ids of the dishes the user marked with a heart.
  Set<String> get favoriteIds =>
      ((_box.get('favorites') as List?) ?? const []).cast<String>().toSet();

  bool isFavorite(String recipeId) => favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    final ids = favoriteIds;
    ids.contains(recipeId) ? ids.remove(recipeId) : ids.add(recipeId);
    await _box.put('favorites', ids.toList());
    notifyListeners();
  }

  /// Version of the starter recipe pack last synced into the recipes box.
  int get starterVersion => (_box.get('starterVersion') as int?) ?? 0;

  Future<void> setStarterVersion(int value) =>
      _box.put('starterVersion', value);

  int get maxMinutes => (_box.get(_maxMinutesKey) as int?) ?? defaultMaxMinutes;

  Future<void> setMaxMinutes(int value) async {
    await _box.put(_maxMinutesKey, value);
    notifyListeners();
  }
}
