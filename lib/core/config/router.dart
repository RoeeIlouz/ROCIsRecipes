import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/cooking_mode_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_detail_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/suggestions_screen.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/pantry',
          builder: (context, state) => const PantryScreen(),
        ),
        GoRoute(
          path: '/suggestions',
          builder: (context, state) => const SuggestionsScreen(),
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
