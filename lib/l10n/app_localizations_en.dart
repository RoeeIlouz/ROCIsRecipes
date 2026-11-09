// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ROCIs Recipes';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark (Slate)';

  @override
  String get amoledTheme => 'AMOLED (Pure Black)';

  @override
  String get glassmorphism => 'Glassmorphism';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get offlineMode => 'Offline Mode Active';

  @override
  String get pantryTitle => 'My kitchen';

  @override
  String get pantryInputHint => 'Type an ingredient';

  @override
  String get addIngredient => 'Add';

  @override
  String get pickFromList => 'Pick from list';

  @override
  String get pantryEmpty => 'Nothing here yet. Add what you have at home.';

  @override
  String get myIngredients => 'What I have';

  @override
  String get appliancesTitle => 'My appliances';

  @override
  String get cookingTimeTitle => 'Time I have';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get applianceStovetop => 'Stovetop';

  @override
  String get applianceOven => 'Oven';

  @override
  String get applianceMicrowave => 'Microwave';

  @override
  String get applianceAirFryer => 'Air fryer';

  @override
  String get applianceBlender => 'Blender';

  @override
  String get applianceKettle => 'Kettle';

  @override
  String get applianceToaster => 'Toaster';

  @override
  String get applianceRiceCooker => 'Rice cooker';
}
