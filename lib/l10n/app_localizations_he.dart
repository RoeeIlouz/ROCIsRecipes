// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'ROCIs Recipes';

  @override
  String get settings => 'הגדרות';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get lightTheme => 'בהיר';

  @override
  String get darkTheme => 'כהה (Slate)';

  @override
  String get amoledTheme => 'AMOLED (שחור מוחלט)';

  @override
  String get glassmorphism => 'אפקט זכוכית (Glassmorphism)';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחק';

  @override
  String get offlineMode => 'מצב לא מקוון פעיל';

  @override
  String get pantryTitle => 'המטבח שלי';

  @override
  String get pantryInputHint => 'הקלידו מצרך';

  @override
  String get addIngredient => 'הוסף';

  @override
  String get pickFromList => 'בחירה מרשימה';

  @override
  String get pantryEmpty => 'עדיין ריק. הוסיפו מה שיש לכם בבית.';

  @override
  String get myIngredients => 'מה יש לי';

  @override
  String get appliancesTitle => 'המכשירים שלי';

  @override
  String get cookingTimeTitle => 'כמה זמן יש לי';

  @override
  String minutesShort(int count) {
    return '$count דק\'';
  }

  @override
  String get applianceStovetop => 'כיריים';

  @override
  String get applianceOven => 'תנור';

  @override
  String get applianceMicrowave => 'מיקרוגל';

  @override
  String get applianceAirFryer => 'איר פרייר';

  @override
  String get applianceBlender => 'בלנדר';

  @override
  String get applianceKettle => 'קומקום';

  @override
  String get applianceToaster => 'טוסטר';

  @override
  String get applianceRiceCooker => 'סיר אורז';
}
