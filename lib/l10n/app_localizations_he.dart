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
}
