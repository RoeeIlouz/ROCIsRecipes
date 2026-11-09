import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rocis_recipes/shared/ui/theme/theme_service.dart';

class AppInitializer {
  /// Initializes core engine, local database, and returns root providers.
  static Future<List<SingleChildWidget>> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Enforce system edge-to-edge overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // 2. Initialize Hive local storage
    await Hive.initFlutter();

    // 3. Initialize Theme Service
    final themeService = ThemeService();
    await themeService.init();

    // Return providers for MultiProvider root
    return [
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
    ];
  }
}
