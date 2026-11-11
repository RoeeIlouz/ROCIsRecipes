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

  /// Starts loading the model into memory in the background so the first request is not slow.
  /// Safe to call often; does nothing when the model is missing or already loaded.
  Future<void> warmUp({bool image = false});

  /// Reads a recipe from pasted text and/or a photo of a recipe. Null when nothing usable came back.
  Future<Map<String, dynamic>?> readRecipe({String? text, Uint8List? image});

  /// Thinks up one new dish from [ingredients] that can be cooked within [maxMinutes].
  Future<Map<String, dynamic>?> inventRecipe({
    required List<String> ingredients,
    required int maxMinutes,
    String? mealType,
  });

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

/// The model answered, but not with a recipe the app can read. Carries what it said so the cause is visible.
class AiReplyException implements Exception {
  AiReplyException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _clip(String s, int n) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length > n ? '${t.substring(0, n)}...' : t;
}

/// Longest a single request may take before the app gives up and says so.
const _requestTimeout = Duration(minutes: 6);

/// How long a loaded model stays in memory after its last use (it is large).
const _idleUnload = Duration(minutes: 3);

/// Gemma 4 E2B (Apache 2.0, not gated) through flutter_edge_ai and LiteRT-LM.
///
/// Loading the model is the slow part, so one instance is kept and reused. The catalog's runtime
/// defaults also switch on the audio encoder, which this app never needs, so it is turned off, and
/// image support is only loaded when a photo is part of the request.
class EdgeRecipeAi implements RecipeAi {
  EdgeRecipeAi() : _variant = LiteRtLmModels.gemma4E2bIt.generic;

  final LiteRtLmVariant _variant;

  InferenceModel? _model;
  bool _modelHasImage = false;
  Timer? _idle;
  Future<void> _queue = Future.value();

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
    Future<void> run(bool? foreground) => FlutterEdgeAi.installModelFromCatalog(
      _variant,
      foreground: foreground,
    ).withProgress((p) => controller.add(p.toDouble())).install();

    // A foreground service keeps a 2.6 GB download alive when the user leaves the app; if the
    // phone refuses it, fall back to a plain download.
    run(true)
        .catchError((Object _) => run(null))
        .then(
          (_) => controller.close(),
          onError: (Object e, StackTrace s) {
            controller.addError(e, s);
            controller.close();
          },
        );
    return controller.stream;
  }

  Future<InferenceModel> _acquire({required bool image}) async {
    _idle?.cancel();
    final current = _model;
    if (current != null && (_modelHasImage || !image)) return current;
    if (current != null) {
      _model = null;
      await current.close();
    }
    final model = await FlutterEdgeAi.getActiveModel(
      defaults: _variant.runtimeDefaults,
      maxTokens: 4096,
      supportImage: image,
      supportAudio: false,
    );
    _model = model;
    _modelHasImage = image;
    return model;
  }

  void _scheduleUnload() {
    _idle?.cancel();
    _idle = Timer(_idleUnload, () async {
      final m = _model;
      _model = null;
      try {
        await m?.close();
      } catch (_) {}
    });
  }

  /// Runs [job] after any earlier request, so two taps never load the model twice at once.
  Future<T> _serial<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> warmUp({bool image = false}) async {
    try {
      if (!await isInstalled()) return;
      await _serial(() async {
        await _acquire(image: image);
        _scheduleUnload();
      });
    } catch (_) {
      // Warming up is only an optimisation; a real request reports the real error.
    }
  }

  /// Why the constrained attempt of the last request failed, shown when the retry also fails.
  String? _note;

  Map<String, dynamic> _json(String reply) {
    final json = extractJsonObject(reply);
    if (json != null) return json;
    final seen = reply.trim().isEmpty
        ? 'empty reply'
        : 'reply: "${_clip(reply, 110)}"';
    throw AiReplyException([seen, ?_note].join(' | '));
  }

  Future<String> _ask(
    String prompt,
    Map<String, Object?> schema, {
    Uint8List? image,
    required int maxOutputTokens,
  }) {
    return _serial(() async {
      _note = null;
      final model = await _acquire(image: image != null);
      try {
        final format = ResponseFormat.jsonSchema(schema);
        // Constrained decoding keeps the reply valid, but it throws when the reply is cut off by the
        // output cap or the engine refuses the schema. Then try once more without the constraint:
        // the reply is parsed leniently afterwards anyway.
        if (model.refusalFor(format) == null) {
          try {
            return await _chat(model, prompt, image, format, maxOutputTokens);
          } on TimeoutException {
            rethrow;
          } catch (e) {
            _note = 'structured: ${_clip('${e.runtimeType}: $e', 90)}';
          }
        } else {
          _note = 'structured output refused by the engine';
        }
        return await _chat(
          model,
          '$prompt\n\n$kRecipeJsonHint\nAnswer with the JSON object only, no other text.',
          image,
          null,
          maxOutputTokens,
        );
      } finally {
        _scheduleUnload();
      }
    }).timeout(_requestTimeout);
  }

  Future<String> _chat(
    InferenceModel model,
    String prompt,
    Uint8List? image,
    ResponseFormat? format,
    int maxOutputTokens,
  ) async {
    InferenceChat? chat;
    try {
      chat = await model.openChat(
        responseFormat: format,
        maxOutputTokens: maxOutputTokens,
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
      try {
        await chat?.close();
      } catch (_) {}
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
      maxOutputTokens: 2400,
    );
    return _json(reply);
  }

  @override
  Future<Map<String, dynamic>?> inventRecipe({
    required List<String> ingredients,
    required int maxMinutes,
    String? mealType,
  }) async {
    final meal = mealType == null ? '' : ' It should be a $mealType dish.';
    final prompt =
        'Invent one simple, realistic dish for a student cooking alone, using mainly these ingredients: '
        '${ingredients.join(', ')}. Salt, pepper and oil are always available. Use at most 2 extra common ingredients '
        'and only if really needed. Total time at most $maxMinutes minutes.$meal Give the title, steps and ingredient '
        'names in Hebrew, with realistic quantities, as JSON. Keep it short: at most 7 steps, each one short sentence, '
        'and at most 9 ingredients.';
    return _json(await _ask(prompt, kRecipeSchema, maxOutputTokens: 2000));
  }

  @override
  Future<List<String>> identifyIngredients(Uint8List image) async {
    final reply = await _ask(
      _photoPrompt,
      kIngredientListSchema,
      image: image,
      maxOutputTokens: 300,
    );
    final json = extractJsonObject(reply);
    return [
      for (final v in (json?['ingredients'] as List?) ?? const [])
        if (v is String && v.trim().isNotEmpty) v.trim(),
    ];
  }
}
