import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rocis_recipes/core/config/router.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/theme/app_theme.dart';
import 'package:rocis_recipes/shared/ui/theme/theme_service.dart';

class RecipesApp extends StatefulWidget {
  const RecipesApp({
    super.key,
    this.providers = const [],
    this.locale = const Locale('he'),
  });

  final List<SingleChildWidget> providers;
  final Locale locale;

  @override
  State<RecipesApp> createState() => _RecipesAppState();
}

class _RecipesAppState extends State<RecipesApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final app = _ThemedApp(router: _router, locale: widget.locale);
    if (widget.providers.isEmpty) return app;
    return MultiProvider(providers: widget.providers, child: app);
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.router, required this.locale});

  final GoRouter router;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    // ThemeService is optional so the app can be built without it in tests.
    final themeService = context.watch<ThemeService?>();
    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.createDarkTheme(
        null,
        isAmoled: themeService?.isAmoled ?? false,
      ),
      themeMode: themeService?.materialThemeMode ?? ThemeMode.dark,
    );
  }
}
