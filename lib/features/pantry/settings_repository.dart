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

  Set<Appliance> get appliances => ((_box.get(_appliancesKey) as List?) ?? const [])
      .map((e) => applianceFromName(e as String))
      .whereType<Appliance>()
      .toSet();

  Future<void> setAppliances(Set<Appliance> value) async {
    await _box.put(_appliancesKey, value.map((e) => e.name).toList());
    notifyListeners();
  }

  Set<String> get stapleIds => ((_box.get(_staplesKey) as List?) ?? const []).cast<String>().toSet();

  Future<void> setStapleIds(Set<String> value) async {
    await _box.put(_staplesKey, value.toList());
    notifyListeners();
  }

  /// Writes [defaults] only if the user has never saved a staples list.
  Future<void> seedStaplesIfUnset(Set<String> defaults) async {
    if (_box.containsKey(_staplesKey)) return;
    await setStapleIds(defaults);
  }

  /// Version of the starter recipe pack last synced into the recipes box.
  int get starterVersion => (_box.get('starterVersion') as int?) ?? 0;

  Future<void> setStarterVersion(int value) => _box.put('starterVersion', value);

  int get maxMinutes => (_box.get(_maxMinutesKey) as int?) ?? defaultMaxMinutes;

  Future<void> setMaxMinutes(int value) async {
    await _box.put(_maxMinutesKey, value);
    notifyListeners();
  }
}
