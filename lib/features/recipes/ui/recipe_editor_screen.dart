import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_icons.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/recipes/photo_source.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

const _units = [
  'unit',
  'g',
  'kg',
  'ml',
  'l',
  'tbsp',
  'tsp',
  'cup',
  'clove',
  'bunch',
  'can',
  'pack',
  'slice',
  'pinch',
];

class _IngredientRow {
  _IngredientRow(
    this.id, {
    String quantity = '',
    this.unit,
    this.optional = false,
  }) : quantity = TextEditingController(text: quantity);

  final String id;
  final TextEditingController quantity;
  String? unit;
  bool optional;
}

/// Create or edit a recipe of your own, optionally with a photo from the camera or gallery.
class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({super.key, this.recipeId});

  final String? recipeId;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _title = TextEditingController();
  final _minutes = TextEditingController(text: '30');
  final _search = TextEditingController();
  final List<_IngredientRow> _ingredients = [];
  final List<TextEditingController> _steps = [TextEditingController()];
  int _servings = 2;
  String _difficulty = 'easy';
  String _mealType = 'dinner';
  String? _imagePath;
  String _query = '';
  String? _error;
  Recipe? _existing;

  @override
  void initState() {
    super.initState();
    final id = widget.recipeId;
    final r = id == null ? null : context.read<RecipeRepository>().byId(id);
    if (r != null && r.isUserCreated) {
      _existing = r;
      _title.text = r.titleHe;
      _minutes.text = '${r.totalMinutes}';
      _servings = r.servings;
      _difficulty = r.difficulty;
      _mealType = r.mealType;
      _imagePath = r.imagePath;
      for (final i in r.ingredients) {
        _ingredients.add(
          _IngredientRow(
            i.ingredientId,
            quantity: i.quantity == null ? '' : formatAmount(i.quantity!),
            unit: i.unit,
            optional: i.optional,
          ),
        );
      }
      _steps
        ..clear()
        ..addAll(r.steps.map((s) => TextEditingController(text: s.textHe)));
      if (_steps.isEmpty) _steps.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    _search.dispose();
    for (final i in _ingredients) {
      i.quantity.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(bool camera) async {
    final path = await context.read<PhotoSource>().pick(camera: camera);
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final steps = _steps
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    String? problem;
    if (_title.text.trim().isEmpty) {
      problem = l10n.edNeedTitle;
    } else if (_ingredients.isEmpty) {
      problem = l10n.edNeedIngredient;
    } else if (steps.isEmpty) {
      problem = l10n.edNeedStep;
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final recipe = Recipe(
      id: _existing?.id ?? 'user_${DateTime.now().microsecondsSinceEpoch}',
      titleHe: _title.text.trim(),
      ingredients: [
        for (final i in _ingredients)
          RecipeIngredient(
            ingredientId: i.id,
            quantity: double.tryParse(
              i.quantity.text.trim().replaceAll(',', '.'),
            ),
            unit: i.unit,
            optional: i.optional,
          ),
      ],
      steps: [for (final t in steps) RecipeStep(textHe: t)],
      totalMinutes: (int.tryParse(_minutes.text.trim()) ?? 30).clamp(1, 600),
      servings: _servings,
      difficulty: _difficulty,
      mealType: _mealType,
      isUserCreated: true,
      imagePath: _imagePath,
      appliances: _existing?.appliances ?? const {},
    );
    await context.read<RecipeRepository>().upsert(recipe);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.edSaved)));
    context.canPop() ? context.pop() : context.go('/suggestions');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalog = context.watch<IngredientCatalog>();
    final matches = _query.trim().isEmpty
        ? const <Ingredient>[]
        : catalog.search(_query.trim(), limit: 6);

    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? l10n.edNew : l10n.edEdit)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          RecipePhotoView(
            photo: null,
            filePath: _imagePath,
            height: 180,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('editor_photo_gallery'),
                onPressed: () => _pickPhoto(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.edPhotoGallery),
              ),
              OutlinedButton.icon(
                key: const Key('editor_photo_camera'),
                onPressed: () => _pickPhoto(true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.edPhotoCamera),
              ),
              if (_imagePath != null)
                TextButton(
                  onPressed: () => setState(() => _imagePath = null),
                  child: Text(l10n.edPhotoRemove),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('editor_title'),
            controller: _title,
            decoration: InputDecoration(labelText: l10n.edName),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('editor_minutes'),
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.edMinutes),
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.edServings),
              IconButton(
                onPressed: _servings > 1
                    ? () => setState(() => _servings--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_servings', key: const Key('editor_servings')),
              IconButton(
                onPressed: _servings < 8
                    ? () => setState(() => _servings++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in kMealTypes)
                ChoiceChip(
                  key: Key('editor_meal_$t'),
                  label: Text(mealTypeLabel(l10n, t)),
                  selected: _mealType == t,
                  onSelected: (_) => setState(() => _mealType = t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in kDifficulties)
                ChoiceChip(
                  key: Key('editor_diff_$d'),
                  label: Text(difficultyLabel(l10n, d)),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.edIngredients, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final row in _ingredients)
            Row(
              key: Key('editor_row_${row.id}'),
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '${ingredientEmoji(row.id, catalog.byId(row.id)?.category ?? '')} ${ingredientLabel(context, catalog, row.id)}',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: Key('editor_qty_${row.id}'),
                    controller: row.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.edQuantity,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: row.unit,
                  hint: Text(l10n.edUnit),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.edNoUnit),
                    ),
                    for (final u in _units)
                      DropdownMenuItem<String?>(
                        value: u,
                        child: Text(unitLabel(l10n, u, 2)),
                      ),
                  ],
                  onChanged: (v) => setState(() => row.unit = v),
                ),
                IconButton(
                  onPressed: () => setState(() => _ingredients.remove(row)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          TextField(
            key: const Key('editor_ingredient_search'),
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.edAddIngredient,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          for (final m in matches)
            ListTile(
              key: Key('editor_pick_${m.id}'),
              dense: true,
              title: Text(ingredientLabel(context, catalog, m.id)),
              onTap: () => setState(() {
                if (!_ingredients.any((r) => r.id == m.id))
                  _ingredients.add(_IngredientRow(m.id));
                _search.clear();
                _query = '';
              }),
            ),
          const SizedBox(height: 20),
          Text(l10n.edSteps, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 14, child: Text('${i + 1}')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: Key('editor_step_$i'),
                      controller: _steps[i],
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l10n.edStepHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_steps.length > 1)
                    IconButton(
                      onPressed: () =>
                          setState(() => _steps.removeAt(i).dispose()),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          TextButton.icon(
            key: const Key('editor_add_step'),
            onPressed: () =>
                setState(() => _steps.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: Text(l10n.edAddStep),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('editor_save'),
            onPressed: _save,
            child: Text(l10n.edSave),
          ),
        ],
      ),
    );
  }
}
