import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart'
    show LaunchUrl;
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// Lists the author and license of every recipe photo (a requirement of CC BY and CC BY-SA).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final credited = context
        .watch<RecipeRepository>()
        .all
        .where((r) => r.photo != null)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: credited.isEmpty
          ? Center(
              key: const Key('credits_empty'),
              child: Text(l10n.creditsEmpty),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.creditsIntro),
                const SizedBox(height: 12),
                for (final r in credited)
                  ListTile(
                    key: Key('credit_${r.id}'),
                    title: Text(r.titleHe),
                    subtitle: Text(
                      l10n.photoCredit(r.photo!.author, r.photo!.license),
                    ),
                    onTap: () => context.read<LaunchUrl>()(
                      Uri.parse(r.photo!.sourceUrl),
                    ),
                  ),
              ],
            ),
    );
  }
}
