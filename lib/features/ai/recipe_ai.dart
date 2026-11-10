import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:rocis_recipes/features/ai/recipe_draft.dart';

/// What the on-device model can do for the app. Everything runs on the phone: nothing the user
/// types or photographs is sent anywhere (only the one-time model download uses the network).
abstract class RecipeAi {
  /// True on devices that can run the model at all (Android on arm64).
  Future<bool> isSupported();

  /// True once the model file is on the phone.
  Future<bool> isInstalled();

  /// Size of the one-time download, for the confirmation dialog.
  int get downloadBytes;

  /// Downloads the model, reporting progress from 0 to 100.
  Stream<double> install();

  /// Reads a recipe from pasted text and/or a photo of a recipe. Null when nothing usable came back.
  Future<Map<String, dynamic>?> readRecipe({String? text, Uint8List? image});

  /// Names of the food items visible in a photo.
  Future<List<String>> identifyIngredients(Uint8List image);
}

const _recipePrompt =
    'You read recipes. Extract the recipe below into JSON with: title (string, in Hebrew), '
    'servings (integer), minutes (integer, total time), ingredients (list of {name, quantity, unit}; '
    'name in Hebrew, quantity a number or omitted, unit one of: g, kg, ml, l, tbsp, tsp, cup, unit, clove, bunch, can, pack, slice, pinch), '
    'steps (list of short Hebrew sentences). Do not invent ingredients or steps that are not in the source.';

const _photoPrompt =
    'List the food items and ingredients you can clearly see in this photo, as JSON '
    '{"ingredients": [names in Hebrew]}. Only items you are sure about, single words or short names, no duplicates.';

/// Gemma 4 E2B (Apache 2.0, not gated) through flutter_edge_ai and LiteRT-LM.
class EdgeRecipeAi implements RecipeAi {
  EdgeRecipeAi() : _variant = LiteRtLmModels.gemma4E2bIt.generic;

  final LiteRtLmVariant _variant;

  static Future<void> initialize() =>
      FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);

  @override
  int get downloadBytes => _variant.file.sizeBytes;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> isInstalled() async {
    try {
      return await FlutterEdgeAi.isModelInstalled(
        _variant.file.installFilename,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<double> install() {
    final controller = StreamController<double>();
    FlutterEdgeAi.installModelFromCatalog(_variant)
        .withProgress((p) => controller.add(p.toDouble()))
        .install()
        .then(
          (_) => controller.close(),
          onError: (Object e, StackTrace s) {
            controller.addError(e, s);
            controller.close();
          },
        );
    return controller.stream;
  }

  Future<String> _ask(
    String prompt,
    Map<String, Object?> schema, {
    Uint8List? image,
  }) async {
    final model = await FlutterEdgeAi.getActiveModel(
      defaults: _variant.runtimeDefaults,
    );
    try {
      final chat = await model.openChat(
        responseFormat: ResponseFormat.jsonSchema(schema),
      );
      await chat.addQueryChunk(
        image == null
            ? Message.text(text: prompt, isUser: true)
            : Message.withImage(text: prompt, imageBytes: image, isUser: true),
      );
      final reply = StringBuffer();
      await for (final r in chat.generateChatResponseAsync()) {
        if (r is TextResponse) reply.write(r.token);
      }
      return reply.toString();
    } finally {
      await model.close();
    }
  }

  @override
  Future<Map<String, dynamic>?> readRecipe({
    String? text,
    Uint8List? image,
  }) async {
    final source = (text == null || text.trim().isEmpty)
        ? ''
        : '\n\nRecipe text:\n${text.trim()}';
    final reply = await _ask(
      '$_recipePrompt$source',
      kRecipeSchema,
      image: image,
    );
    return extractJsonObject(reply);
  }

  @override
  Future<List<String>> identifyIngredients(Uint8List image) async {
    final reply = await _ask(_photoPrompt, kIngredientListSchema, image: image);
    final json = extractJsonObject(reply);
    return [
      for (final v in (json?['ingredients'] as List?) ?? const [])
        if (v is String && v.trim().isNotEmpty) v.trim(),
    ];
  }
}
