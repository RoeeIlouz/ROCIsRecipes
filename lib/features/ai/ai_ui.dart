import 'dart:typed_data';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/ai/recipe_ai.dart';
import 'package:rocis_recipes/features/ai/recipe_draft.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/recipes/photo_source.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// Makes sure the on-device model is on the phone, asking before the one-time download.
/// Returns false when the user declines or the download fails.
/// A short, readable reason for an AI failure, so the user (and I) can tell what went wrong.
String aiErrorText(AppLocalizations l10n, Object e) {
  if (e is TimeoutException) return l10n.aiTimedOut;
  final text = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return l10n.aiErrorDetail(
    text.length > 140 ? '${text.substring(0, 140)}...' : text,
  );
}

Future<bool> ensureAiModel(BuildContext context) async {
  final ai = context.read<RecipeAi>();
  final l10n = AppLocalizations.of(context);
  if (await ai.isInstalled()) return true;
  if (!context.mounted) return false;
  final gb = (ai.downloadBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
  final agree = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.aiDownloadTitle),
      content: Text(l10n.aiDownloadBody(gb)),
      actions: [
        TextButton(
          key: const Key('ai_download_cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('ai_download_confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.aiDownload),
        ),
      ],
    ),
  );
  if (agree != true || !context.mounted) return false;

  final progress = ValueNotifier<double>(0);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.aiDownloading),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, p, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                key: const Key('ai_download_progress'),
                value: p / 100,
              ),
              const SizedBox(height: 8),
              Text('${p.toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    ),
  );
  var ok = true;
  try {
    await for (final p in ai.install()) {
      progress.value = p;
    }
  } catch (_) {
    ok = false;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  return ok && await ai.isInstalled();
}

Future<Uint8List?> _pickBytes(BuildContext context, bool camera) =>
    context.read<PhotoSource>().pickBytes(camera: camera);

/// Bottom sheet that turns pasted text and/or a photo of a recipe into a draft [Recipe].
class AiImportSheet extends StatefulWidget {
  const AiImportSheet({super.key});

  @override
  State<AiImportSheet> createState() => _AiImportSheetState();
}

class _AiImportSheetState extends State<AiImportSheet> {
  final _text = TextEditingController();
  Uint8List? _image;
  bool _busy = false;
  bool _failed = false;
  String? _detail;

  @override
  void initState() {
    super.initState();
    // Start loading the model while the user types or picks a photo.
    context.read<RecipeAi>().warmUp();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _photo(bool camera) async {
    final bytes = await _pickBytes(context, camera);
    if (bytes != null && mounted) setState(() => _image = bytes);
  }

  Future<void> _analyze() async {
    if (_text.text.trim().isEmpty && _image == null) return;
    final ai = context.read<RecipeAi>();
    final catalog = context.read<IngredientCatalog>();
    if (!await ensureAiModel(context) || !mounted) return;
    setState(() {
      _busy = true;
      _failed = false;
      _detail = null;
    });
    Recipe? draft;
    try {
      final json = await ai.readRecipe(text: _text.text, image: _image);
      draft = json == null ? null : recipeFromAiJson(json, catalog);
    } catch (e) {
      draft = null;
      _detail = aiErrorText(AppLocalizations.of(context), e);
    }
    if (!mounted) return;
    if (draft == null) {
      setState(() {
        _busy = false;
        _failed = true;
      });
    } else {
      Navigator.of(context).pop(draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aiImportTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aiOnDeviceNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('ai_text'),
              controller: _text,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(hintText: l10n.aiImportHint),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('ai_photo_gallery'),
                  onPressed: _busy ? null : () => _photo(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.edPhotoGallery),
                ),
                OutlinedButton.icon(
                  key: const Key('ai_photo_camera'),
                  onPressed: _busy ? null : () => _photo(true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.edPhotoCamera),
                ),
                if (_image != null)
                  Chip(
                    label: Text(l10n.aiPhotoAttached),
                    avatar: const Icon(Icons.check, size: 16),
                  ),
              ],
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.aiFailed,
                  key: const Key('ai_failed'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_failed && _detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _detail!,
                  key: const Key('ai_error_detail'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ElapsedText(
                  l10n.aiLoadingModel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('ai_analyze'),
              onPressed: _busy ? null : _analyze,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.aiAnalyze),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo of the kitchen in, confirmed ingredients out (added to the pantry).
Future<void> scanPantryPhoto(
  BuildContext context, {
  required bool camera,
}) async {
  final l10n = AppLocalizations.of(context);
  final ai = context.read<RecipeAi>();
  final catalog = context.read<IngredientCatalog>();
  final pantry = context.read<PantryRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final bytes = await _pickBytes(context, camera);
  if (bytes == null || !context.mounted) return;
  if (!await ensureAiModel(context) || !context.mounted) return;

  List<String> ids;
  try {
    ids = ingredientIdsFromNames(await ai.identifyIngredients(bytes), catalog);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.aiFailed} ${aiErrorText(l10n, e)}')),
    );
    return;
  }
  if (ids.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiNothingFound)));
    return;
  }
  if (!context.mounted) return;
  final chosen = await showDialog<Set<String>>(
    context: context,
    builder: (ctx) {
      final selected = {...ids};
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.aiFoundTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in ids)
                  CheckboxListTile(
                    key: Key('ai_found_$id'),
                    value: selected.contains(id),
                    title: Text(ingredientLabel(ctx, catalog, id)),
                    onChanged: (v) => setState(
                      () => v == true ? selected.add(id) : selected.remove(id),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('ai_found_add'),
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(l10n.aiFoundAdd),
            ),
          ],
        ),
      );
    },
  );
  if (chosen == null) return;
  for (final id in chosen) {
    await pantry.upsert(PantryItem(ingredientId: id));
  }
}

/// Asks the model for a new dish from what is in the pantry and opens it in the editor for review.
Future<void> inventFromPantry(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final ai = context.read<RecipeAi>();
  final catalog = context.read<IngredientCatalog>();
  final pantry = context.read<PantryRepository>();
  final minutes = context.read<SettingsRepository>().maxMinutes;
  final names = [
    for (final item in pantry.items)
      item.label ?? ingredientLabel(context, catalog, item.ingredientId),
  ];
  if (names.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiNeedIngredients)));
    return;
  }
  if (!await ensureAiModel(context) || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ElapsedText('${l10n.aiInventing} ${l10n.aiLoadingModel}'),
            ),
          ],
        ),
      ),
    ),
  );
  Recipe? draft;
  String? reason;
  try {
    final json = await ai.inventRecipe(ingredients: names, maxMinutes: minutes);
    draft = json == null ? null : recipeFromAiJson(json, catalog);
  } catch (e) {
    draft = null;
    reason = aiErrorText(l10n, e);
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (draft == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reason == null ? l10n.aiFailed : '${l10n.aiFailed} $reason',
        ),
      ),
    );
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(l10n.aiDraftNote)));
  router.push('/recipe-edit', extra: draft);
}

/// Entry sheet for the pantry screen: take or choose a photo to scan.
Future<void> showPantryScanSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  context.read<RecipeAi>().warmUp(image: true);
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.aiScanTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.aiOnDeviceNote, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('ai_scan_gallery'),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.edPhotoGallery),
              onPressed: () {
                Navigator.pop(ctx);
                scanPantryPhoto(context, camera: false);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('ai_scan_camera'),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.edPhotoCamera),
              onPressed: () {
                Navigator.pop(ctx);
                scanPantryPhoto(context, camera: true);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// A message with a live seconds counter, so a slow first load does not look like a freeze.
class _ElapsedText extends StatefulWidget {
  const _ElapsedText(this.message, {this.style});

  final String message;
  final TextStyle? style;

  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<_ElapsedText> {
  final _watch = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    '${widget.message} (${_watch.elapsed.inSeconds}s)',
    style: widget.style,
  );
}
