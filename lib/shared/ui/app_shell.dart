import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// Bottom navigation shell: Pantry, Suggestions, Weekly menu, Shopping.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            key: const Key('nav_pantry'),
            icon: const Icon(Icons.kitchen_rounded),
            label: l10n.navPantry,
          ),
          NavigationDestination(
            key: const Key('nav_suggestions'),
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: l10n.navSuggestions,
          ),
          NavigationDestination(
            key: const Key('nav_plan'),
            icon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navPlan,
          ),
          NavigationDestination(
            key: const Key('nav_shopping'),
            icon: const Icon(Icons.shopping_cart_rounded),
            label: l10n.navShopping,
          ),
        ],
      ),
    );
  }
}
