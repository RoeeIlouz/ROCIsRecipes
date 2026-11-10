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

  @override
  String get tabCookNow => 'לבשל עכשיו';

  @override
  String get tabAlmostThere => 'כמעט שם';

  @override
  String missingCount(int count) {
    return 'חסרים $count';
  }

  @override
  String get noMatches =>
      'אין עדיין מנות מתאימות. הוסיפו מצרכים, מכשירים או יותר זמן.';

  @override
  String get ingredientsTitle => 'מצרכים';

  @override
  String get stepsTitle => 'שלבים';

  @override
  String get missingBadge => 'חסר';

  @override
  String get addMissingToList => 'הוסיפו את החסר לרשימת הקניות';

  @override
  String get addedToList => 'נוספו לרשימת הקניות';

  @override
  String get startCooking => 'התחילו לבשל';

  @override
  String stepOfTotal(int current, int total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get nextStep => 'הבא';

  @override
  String get previousStep => 'הקודם';

  @override
  String get finishCooking => 'סיימתי';

  @override
  String get startTimer => 'הפעל טיימר';

  @override
  String get pauseTimer => 'השהה';

  @override
  String get navPantry => 'מטבח';

  @override
  String get navSuggestions => 'מנות';

  @override
  String get navShopping => 'קניות';

  @override
  String get shoppingTitle => 'רשימת קניות';

  @override
  String get shoppingInputHint => 'הוסיפו פריט';

  @override
  String get doneSection => 'בעגלה';

  @override
  String get clearChecked => 'נקה מסומנים';

  @override
  String get shoppingEmpty => 'הרשימה ריקה.';

  @override
  String get timerDone => 'הזמן נגמר!';

  @override
  String get pricesTitle => 'מחירים משוערים';

  @override
  String get useMyLocation => 'השתמשו במיקום שלי כדי למצוא את הסניף הקרוב';

  @override
  String get pickBranch => 'בחרו סניף';

  @override
  String get estimateLabel => 'הערכה';

  @override
  String partialTotal(int count) {
    return 'ל-$count פריטים אין מחיר';
  }

  @override
  String get noPriceData => 'אין נתוני מחיר לרשימה';

  @override
  String tooFar(int km) {
    return 'אין סניף ברדיוס $km ק\"מ';
  }

  @override
  String distanceKm(String km) {
    return 'במרחק $km ק\"מ';
  }

  @override
  String get navigate => 'ניווט';

  @override
  String staleWarning(String date) {
    return 'ייתכן שהמחירים לא עדכניים (עודכנו לאחרונה $date)';
  }

  @override
  String get osmAttribution => 'נתוני מפה מתורמי OpenStreetMap';

  @override
  String get locationUnavailable => 'המיקום לא זמין, בחרו סניף בעצמכם';

  @override
  String itemEstimate(String price) {
    return 'כ-$price';
  }

  @override
  String get pickerTitle => 'בחרו מצרכים';

  @override
  String get pickerSearchHint => 'חיפוש מצרכים';

  @override
  String get pickerDone => 'סיום';

  @override
  String get pickerEmpty => 'לא נמצאו מצרכים';

  @override
  String get closeLabel => 'סגירה';

  @override
  String get categoryAll => 'הכול';

  @override
  String get catProduce => 'ירקות ופירות';

  @override
  String get catDairy => 'חלב וביצים';

  @override
  String get catMeat => 'בשר ודגים';

  @override
  String get catGrains => 'דגנים וקטניות';

  @override
  String get catPantry => 'מזווה';

  @override
  String get catSpices => 'תבלינים';

  @override
  String get catSnacks => 'אגוזים ושתייה';

  @override
  String get mealAll => 'כל הארוחות';

  @override
  String get mealBreakfast => 'ארוחת בוקר';

  @override
  String get mealLunch => 'צהריים';

  @override
  String get mealDinner => 'ערב';

  @override
  String get mealSnack => 'נשנוש';

  @override
  String get mealDessert => 'קינוח';

  @override
  String get diffEasy => 'קל';

  @override
  String get diffMedium => 'בינוני';

  @override
  String servingsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מנות',
      one: 'מנה אחת',
    );
    return '$_temp0';
  }

  @override
  String photoCredit(String author, String license) {
    return 'צילום: $author, $license';
  }

  @override
  String get creditsTitle => 'קרדיטים לתמונות';

  @override
  String get creditsIntro =>
      'תמונות המתכונים מגיעות מ-Wikimedia Commons ברישיונות חופשיים. לחיצה על תמונה פותחת את עמוד המקור.';

  @override
  String get creditsEmpty => 'עדיין אין קרדיטים לתמונות.';

  @override
  String get unitUnit => 'יח\'';

  @override
  String get unitG => 'גרם';

  @override
  String get unitKg => 'ק\"ג';

  @override
  String get unitMl => 'מ\"ל';

  @override
  String get unitL => 'ליטר';

  @override
  String unitTbsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כפות',
      one: 'כף',
    );
    return '$_temp0';
  }

  @override
  String unitTsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כפיות',
      one: 'כפית',
    );
    return '$_temp0';
  }

  @override
  String unitCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כוסות',
      one: 'כוס',
    );
    return '$_temp0';
  }

  @override
  String unitClove(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'שיניים',
      one: 'שן',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'צרורות',
      one: 'צרור',
    );
    return '$_temp0';
  }

  @override
  String unitCan(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'קופסאות',
      one: 'קופסה',
    );
    return '$_temp0';
  }

  @override
  String unitPack(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'חבילות',
      one: 'חבילה',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'פרוסות',
      one: 'פרוסה',
    );
    return '$_temp0';
  }

  @override
  String get unitPinch => 'קורט';

  @override
  String get recipeMissingTitle => 'חסר';

  @override
  String get optionalLabel => 'אופציונלי';

  @override
  String get chooseArea => 'או בחרו אזור לפי עיר או רחוב';

  @override
  String get areaSearchHint => 'עיר, רחוב או שם סניף';

  @override
  String get areaNoResults => 'לא נמצא סניף שם';

  @override
  String usingArea(String label) {
    return 'אזור: $label';
  }
}
