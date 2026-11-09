import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

String formatTimer(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _index = 0;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setAwake(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _setAwake(false);
    super.dispose();
  }

  Future<void> _setAwake(bool on) async {
    try {
      await (on ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {
      // Keeping the screen awake is a convenience; ignore platform failures.
    }
  }

  void _goTo(int index, RecipeStep step) {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _index = index;
      _remaining = step.timerSeconds ?? 0;
    });
  }

  void _toggleTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _timer = null;
        });
      } else {
        setState(() => _remaining -= 1);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipe = context.watch<RecipeRepository>().byId(widget.recipeId);
    if (recipe == null || recipe.steps.isEmpty) return Scaffold(appBar: AppBar());

    final step = recipe.steps[_index];
    final isHebrew = Localizations.localeOf(context).languageCode == 'he';
    final stepText = (isHebrew || step.textEn == null || step.textEn!.isEmpty) ? step.textHe : step.textEn!;
    final isFirst = _index == 0;
    final isLast = _index == recipe.steps.length - 1;
    final timerSeconds = step.timerSeconds;
    final shownSeconds = _timer == null && _remaining == 0 ? (timerSeconds ?? 0) : _remaining;

    return Scaffold(
      appBar: AppBar(title: Text(recipeTitle(context, recipe), maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.stepOfTotal(_index + 1, recipe.steps.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(stepText, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
            if (timerSeconds != null)
              Row(
                key: const Key('step_timer'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formatTimer(shownSeconds), style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    key: const Key('timer_toggle'),
                    onPressed: _toggleTimer,
                    child: Text(_timer == null ? l10n.startTimer : l10n.pauseTimer),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isFirst)
                  OutlinedButton(
                    key: const Key('prev_step_button'),
                    onPressed: () => _goTo(_index - 1, recipe.steps[_index - 1]),
                    child: Text(l10n.previousStep),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('next_step_button'),
                  onPressed: isLast ? () => context.pop() : () => _goTo(_index + 1, recipe.steps[_index + 1]),
                  child: Text(isLast ? l10n.finishCooking : l10n.nextStep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
