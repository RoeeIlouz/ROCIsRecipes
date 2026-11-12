import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart'
    show LaunchUrl;
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// A recipe photo, cropped to fill its box. Without a photo, or if the file cannot be
/// loaded, a clean placeholder is shown (never a wrong picture).
class RecipePhotoView extends StatelessWidget {
  const RecipePhotoView({
    super.key,
    required this.photo,
    this.filePath,
    this.width,
    this.height,
    this.kind,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final RecipePhoto? photo;

  /// A photo the user took or picked (stored on the device), used when there is no credited [photo].
  final String? filePath;
  final double? width;
  final double? height;

  /// The dish's [recipeKind]; tints and labels the placeholder shown when there is no photo.
  final String? kind;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(width: width, height: height, kind: kind);
    final p = photo;
    final f = filePath;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: (p == null && f == null)
            ? placeholder
            : (p == null
                  ? Image.file(
                      File(f!),
                      key: const Key('recipe_photo_image'),
                      fit: BoxFit.cover,
                      width: width,
                      height: height,
                      cacheWidth: 720,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : Image.asset(
                      p.asset,
                      key: const Key('recipe_photo_image'),
                      fit: BoxFit.cover,
                      width: width,
                      height: height,
                      // Decode near display size so a list of photos stays light on memory.
                      cacheWidth: 720,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => placeholder,
                    )),
      ),
    );
  }
}

class _KindStyle {
  const _KindStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const _kindStyles = <String, _KindStyle>{
  'chicken': _KindStyle(Icons.dinner_dining, Color(0xFFF5A524)),
  'beef': _KindStyle(Icons.kebab_dining, Color(0xFFD0605A)),
  'fish': _KindStyle(Icons.set_meal, Color(0xFF3FA7C4)),
  'vegetarian': _KindStyle(Icons.eco, Color(0xFF4CAF7A)),
  'dessert': _KindStyle(Icons.bakery_dining, Color(0xFFD981A8)),
  'breakfast': _KindStyle(Icons.free_breakfast, Color(0xFFE8C44A)),
};

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, this.kind});

  final double? width;
  final double? height;
  final String? kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = kind == null ? null : _kindStyles[kind];
    final base = scheme.surfaceContainerHigh;
    final colors = style == null
        ? [scheme.primaryContainer, scheme.secondaryContainer]
        : [
            Color.alphaBlend(style.color.withValues(alpha: 0.42), base),
            Color.alphaBlend(style.color.withValues(alpha: 0.14), base),
          ];
    final side = [width, height]
        .whereType<double>()
        .where((v) => v.isFinite)
        .fold<double?>(null, (m, v) => m == null || v < m ? v : m);
    return Container(
      key: const Key('photo_placeholder'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          style?.icon ?? Icons.restaurant_rounded,
          size: side == null ? null : (side * 0.42).clamp(24, 72).toDouble(),
          color: style == null
              ? scheme.onPrimaryContainer.withValues(alpha: 0.6)
              : Color.lerp(style.color, Colors.white, 0.4),
        ),
      ),
    );
  }
}

/// "Photo: AUTHOR, LICENSE"; tapping it opens the photo's page on Wikimedia Commons.
class PhotoCredit extends StatelessWidget {
  const PhotoCredit({super.key, required this.photo});

  final RecipePhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: const Key('photo_credit'),
      onTap: () => context.read<LaunchUrl>()(Uri.parse(photo.sourceUrl)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          l10n.photoCredit(photo.author, photo.license),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
