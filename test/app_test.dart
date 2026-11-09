import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/app.dart';
import 'package:rocis_recipes/shared/ui/theme/theme_service.dart';

import 'helpers/test_env.dart';

void main() {
  testWidgets('defaults to Hebrew RTL', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(RecipesApp(providers: env.providers));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('switches to English LTR', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(RecipesApp(providers: env.providers, locale: const Locale('en')));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);
  });

  testWidgets('applies the AMOLED theme from ThemeService', (tester) async {
    final env = await TestEnv.create();
    late ThemeService themeService;
    final dir = Directory.systemTemp.createTempSync('rocis_theme_');
    await tester.runAsync(() async {
      Hive.init(dir.path);
      themeService = ThemeService();
      await themeService.init();
      await themeService.setThemeMode(AppThemeMode.amoled);
    });
    await tester.pumpWidget(RecipesApp(providers: [
      ...env.providers,
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
    ]));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(ctx).scaffoldBackgroundColor, Colors.black);

    await tester.runAsync(() => Hive.close());
    dir.deleteSync(recursive: true);
  });
}
