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
    this.themeService,
  });

  final List<SingleChildWidget> providers;
  final Locale locale;
  final ThemeService? themeService;

  @override
  State<RecipesApp> createState() => _RecipesAppState();
}

class _RecipesAppState extends State<RecipesApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final app = ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[widget.themeService]),
      builder: (context, _) {
        final mode = widget.themeService?.themeMode;
        return MaterialApp.router(
          routerConfig: _router,
          locale: widget.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.createDarkTheme(null, isAmoled: mode == AppThemeMode.amoled),
          themeMode: widget.themeService?.materialThemeMode ?? ThemeMode.dark,
        );
      },
    );
    if (widget.providers.isEmpty) return app;
    return MultiProvider(providers: widget.providers, child: app);
  }
}
