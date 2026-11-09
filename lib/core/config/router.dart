import 'package:go_router/go_router.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/cooking_mode_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_detail_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/suggestions_screen.dart';
import 'package:rocis_recipes/features/shopping/ui/shopping_screen.dart';
import 'package:rocis_recipes/shared/ui/app_shell.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/pantry'),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/pantry', builder: (context, state) => const PantryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/suggestions', builder: (context, state) => const SuggestionsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/shopping', builder: (context, state) => const ShoppingScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (context, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cook/:id',
          builder: (context, state) => CookingModeScreen(recipeId: state.pathParameters['id']!),
        ),
      ],
    );
