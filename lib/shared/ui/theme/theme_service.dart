import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

enum AppThemeMode { system, light, dark, amoled }

class ThemeService extends ChangeNotifier {
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'app_theme_mode';
  static const String _glassKey = 'use_glassmorphism';

  late Box _box;
  AppThemeMode _mode = AppThemeMode.dark;
  bool _useGlassmorphism = true;

  AppThemeMode get themeMode => _mode;
  bool get isAmoled => _mode == AppThemeMode.amoled;
  bool get useGlassmorphism => _useGlassmorphism;

  ThemeMode get materialThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedMode = _box.get(_themeKey, defaultValue: 'dark') as String;
    _useGlassmorphism = _box.get(_glassKey, defaultValue: true) as bool;

    switch (savedMode) {
      case 'light':
        _mode = AppThemeMode.light;
        break;
      case 'amoled':
        _mode = AppThemeMode.amoled;
        break;
      case 'system':
        _mode = AppThemeMode.system;
        break;
      default:
        _mode = AppThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _mode = mode;
    await _box.put(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleGlassmorphism(bool enabled) async {
    _useGlassmorphism = enabled;
    await _box.put(_glassKey, enabled);
    notifyListeners();
  }
}
