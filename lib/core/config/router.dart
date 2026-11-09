import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';

GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/pantry',
          builder: (context, state) => const PantryScreen(),
        ),
      ],
    );
