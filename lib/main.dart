import 'package:flutter/material.dart';
import 'package:rocis_recipes/app.dart';
import 'package:rocis_recipes/core/services/app_initializer.dart';

Future<void> main() async {
  final providers = await AppInitializer.initialize();
  runApp(RecipesApp(providers: providers));
}
