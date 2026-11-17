import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/plan/plan_builder.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

const _budgets = [200, 300, 400, 500, 700];

/// First-run setup in three short steps: what the app does, budget and household, and the
/// supermarket area. It ends with a finished week menu, or skips to Home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  int? _budget;
  int _people = 1;

  Future<void> _finish({required bool build}) async {
    final settings = context.read<SettingsRepository>();
    final router = GoRouter.of(context);
    if (_budget != null) await settings.setWeeklyBudget(_budget);
    await settings.setHouseholdSize(_people);
    if (build && mounted) await buildWeekPlanNow(context);
    await settings.setOnboardingDone(true);
    router.go(build ? '/plan' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final body = switch (_step) {
      0 => _Page(
        emoji: '🍳',
        title: l10n.onbWelcomeTitle,
        body: l10n.onbWelcomeBody,
        child: const SizedBox.shrink(),
      ),
      1 => _Page(
        emoji: '💰',
        title: l10n.onbBudgetTitle,
        body: null,
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in _budgets)
                  ChoiceChip(
                    key: Key('onb_budget_$b'),
                    label: Text('₪$b'),
                    selected: _budget == b,
                    onSelected: (_) => setState(() => _budget = b),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(l10n.onbPeopleTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  key: const Key('onb_people_minus'),
                  onPressed: _people > 1
                      ? () => setState(() => _people--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '$_people',
                    key: const Key('onb_people_value'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('onb_people_plus'),
                  onPressed: _people < 8
                      ? () => setState(() => _people++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      _ => _Page(
        emoji: '🛒',
        title: l10n.onbShopTitle,
        body: l10n.onbShopBody,
        child: Consumer<NearbyController>(
          builder: (context, nearby, _) => nearby.location != null
              ? Chip(
                  key: const Key('onb_located'),
                  avatar: const Icon(Icons.check_circle, size: 18),
                  label: Text(l10n.onbLocated),
                )
              : OutlinedButton.icon(
                  key: const Key('onb_locate'),
                  onPressed: nearby.locate,
                  icon: const Icon(Icons.my_location),
                  label: Text(l10n.onbLocate),
                ),
        ),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const Key('onb_skip'),
                  onPressed: () => _finish(build: false),
                  child: Text(l10n.onbSkip),
                ),
              ),
              Expanded(child: SingleChildScrollView(child: body)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _step
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _step == 0
                    ? FilledButton(
                        key: const Key('onb_start'),
                        onPressed: () => setState(() => _step = 1),
                        child: Text(l10n.onbStart),
                      )
                    : _step == 1
                    ? FilledButton(
                        key: const Key('onb_next'),
                        onPressed: () => setState(() => _step = 2),
                        child: Text(l10n.onbNext),
                      )
                    : FilledButton.icon(
                        key: const Key('onb_finish_build'),
                        onPressed: () => _finish(build: true),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.onbFinish),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.emoji,
    required this.title,
    required this.body,
    required this.child,
  });

  final String emoji;
  final String title;
  final String? body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 54)),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 12),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}
