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
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final RecipePhoto? photo;

  /// A photo the user took or picked (stored on the device), used when there is no credited [photo].
  final String? filePath;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(width: width, height: height);
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('photo_placeholder'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: scheme.onPrimaryContainer.withValues(alpha: 0.6),
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
